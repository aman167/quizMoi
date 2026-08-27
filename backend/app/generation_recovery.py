import asyncio
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from time import monotonic

from .schemas import GeneratedQuizPayload


class IdempotencyConflictError(Exception):
    """The same request id was reused for different study material."""


class GenerationRecoveryCapacityError(Exception):
    """Too many generation operations are currently being retained."""


@dataclass
class _GenerationEntry:
    fingerprint: str
    created_at: float
    task: asyncio.Task[GeneratedQuizPayload] | None = None
    result: GeneratedQuizPayload | None = None


class GenerationRecoveryStore:
    """Keeps short-lived generation work so a disconnected client can recover it."""

    def __init__(self, *, max_entries: int = 64, ttl_seconds: float = 3600.0):
        self._max_entries = max_entries
        self._ttl_seconds = ttl_seconds
        self._entries: dict[str, _GenerationEntry] = {}
        self._lock = asyncio.Lock()

    async def run(
        self,
        request_id: str,
        fingerprint: str,
        operation: Callable[[], Awaitable[GeneratedQuizPayload]],
    ) -> GeneratedQuizPayload:
        async with self._lock:
            self._prune_locked()
            entry = self._entries.get(request_id)
            if entry is not None and entry.fingerprint != fingerprint:
                raise IdempotencyConflictError(
                    "This generation request id was already used for different content."
                )

            if entry is None:
                self._make_room_locked()
                entry = _GenerationEntry(
                    fingerprint=fingerprint,
                    created_at=monotonic(),
                    task=asyncio.create_task(operation()),
                )
                self._entries[request_id] = entry
            elif entry.result is not None:
                return entry.result
            elif entry.task is not None and entry.task.done():
                try:
                    entry.result = entry.task.result()
                except Exception:
                    del self._entries[request_id]
                    raise
                entry.task = None
                return entry.result

            task = entry.task

        if task is None:
            raise RuntimeError("Generation recovery entry has no task or result.")

        try:
            result = await asyncio.shield(task)
        except asyncio.CancelledError:
            # Shielding lets the provider request finish even if the mobile client
            # disconnects. A retry with the same id can then recover its result.
            raise
        except Exception:
            async with self._lock:
                current = self._entries.get(request_id)
                if current is entry:
                    del self._entries[request_id]
            raise

        async with self._lock:
            current = self._entries.get(request_id)
            if current is entry:
                entry.result = result
                entry.task = None
        return result

    def _prune_locked(self) -> None:
        cutoff = monotonic() - self._ttl_seconds
        expired = [
            request_id
            for request_id, entry in self._entries.items()
            if entry.result is not None and entry.created_at < cutoff
        ]
        for request_id in expired:
            del self._entries[request_id]

    def _make_room_locked(self) -> None:
        if len(self._entries) < self._max_entries:
            return
        completed = sorted(
            (
                (entry.created_at, request_id)
                for request_id, entry in self._entries.items()
                if entry.result is not None
            )
        )
        if completed:
            del self._entries[completed[0][1]]
            return
        raise GenerationRecoveryCapacityError(
            "Too many quiz generations are already in progress."
        )
