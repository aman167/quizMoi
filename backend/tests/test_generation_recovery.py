import asyncio

import pytest

from app.generation_recovery import GenerationRecoveryStore
from app.schemas import GeneratedQuizPayload


def _payload() -> GeneratedQuizPayload:
    return GeneratedQuizPayload.model_validate(
        {
            "title": "Le trajet de Marie",
            "questions": [
                {
                    "prompt": f"Question {index + 1}",
                    "options": [
                        {"id": "a", "text": "En train"},
                        {"id": "b", "text": "En avion"},
                        {"id": "c", "text": "À vélo"},
                        {"id": "d", "text": "À pied"},
                    ],
                    "correctOptionId": "a",
                    "explanation": "Le texte donne la réponse.",
                    "sourceExcerpt": "Marie prend le train.",
                    "concepts": [
                        {"name": "Les transports", "category": "vocabulary"}
                    ],
                }
                for index in range(5)
            ],
        }
    )


@pytest.mark.asyncio
async def test_cancelled_waiter_can_recover_without_repeating_generation() -> None:
    store = GenerationRecoveryStore()
    operation_started = asyncio.Event()
    allow_completion = asyncio.Event()
    call_count = 0

    async def generate() -> GeneratedQuizPayload:
        nonlocal call_count
        call_count += 1
        operation_started.set()
        await allow_completion.wait()
        return _payload()

    first_waiter = asyncio.create_task(
        store.run("generation-disconnected", "same-fingerprint", generate)
    )
    await operation_started.wait()
    first_waiter.cancel()
    with pytest.raises(asyncio.CancelledError):
        await first_waiter

    allow_completion.set()
    recovered = await store.run(
        "generation-disconnected", "same-fingerprint", generate
    )

    assert recovered.title == "Le trajet de Marie"
    assert call_count == 1
