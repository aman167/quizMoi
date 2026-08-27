import asyncio
import ipaddress
import re
import socket
from collections.abc import Sequence
from dataclasses import dataclass
from html import escape
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, urlunsplit

import httpx


MAX_WEB_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_ARTICLE_CHARACTERS = 12_000
MIN_ARTICLE_CHARACTERS = 200
MAX_REDIRECTS = 3


class WebArticleError(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        super().__init__(message)
        self.status_code = status_code
        self.code = code


@dataclass(frozen=True)
class WebArticleContent:
    url: str
    title: str
    text: str
    was_truncated: bool


class _ArticleHtmlParser(HTMLParser):
    _ignored_tags = {
        "aside",
        "button",
        "canvas",
        "footer",
        "form",
        "header",
        "nav",
        "noscript",
        "script",
        "style",
        "svg",
        "template",
    }
    _block_tags = {
        "article",
        "blockquote",
        "br",
        "div",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "li",
        "main",
        "p",
        "section",
    }

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._stack: list[str] = []
        self._title: list[str] = []
        self._article: list[str] = []
        self._main: list[str] = []
        self._body: list[str] = []

    @property
    def title(self) -> str:
        return _normalize_inline(" ".join(self._title))

    @property
    def article_text(self) -> str:
        candidates = (
            _normalize_blocks(self._article),
            _normalize_blocks(self._main),
            _normalize_blocks(self._body),
        )
        return next(
            (value for value in candidates if len(value) >= MIN_ARTICLE_CHARACTERS),
            candidates[-1],
        )

    def handle_starttag(
        self,
        tag: str,
        _attrs: list[tuple[str, str | None]],
    ) -> None:
        normalized = tag.casefold()
        self._stack.append(normalized)
        if normalized in self._block_tags:
            self._append_to_active("\n")

    def handle_startendtag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        self.handle_starttag(tag, attrs)
        self.handle_endtag(tag)

    def handle_endtag(self, tag: str) -> None:
        normalized = tag.casefold()
        if normalized in self._block_tags:
            self._append_to_active("\n")
        for index in range(len(self._stack) - 1, -1, -1):
            if self._stack[index] == normalized:
                del self._stack[index:]
                return

    def handle_data(self, data: str) -> None:
        if not data.strip() or any(tag in self._ignored_tags for tag in self._stack):
            return
        if "title" in self._stack:
            self._title.append(data)
        self._append_to_active(data)

    def _append_to_active(self, value: str) -> None:
        if "body" not in self._stack:
            return
        self._body.append(value)
        if "main" in self._stack:
            self._main.append(value)
        if "article" in self._stack:
            self._article.append(value)


def _normalize_inline(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def _normalize_blocks(values: list[str]) -> str:
    lines = []
    for raw_line in "".join(values).splitlines():
        line = _normalize_inline(raw_line)
        if line and (not lines or line != lines[-1]):
            lines.append(line)
    return "\n".join(lines)


def extract_web_article(html: str, final_url: str) -> WebArticleContent:
    parser = _ArticleHtmlParser()
    try:
        parser.feed(html)
        parser.close()
    except Exception as error:
        raise WebArticleError(
            422,
            "article_unreadable",
            "quizMoi could not read useful article text from this page.",
        ) from error

    text = parser.article_text
    lowered = text.casefold()
    paywall_phrases = (
        "subscribe to continue reading",
        "sign in to continue reading",
        "abonnez-vous pour lire",
        "réservé aux abonnés",
        "cet article est réservé",
    )
    if len(text) < 2_000 and any(phrase in lowered for phrase in paywall_phrases):
        raise WebArticleError(
            422,
            "article_paywalled",
            "This article appears to require a subscription or sign-in.",
        )
    if len(text) < MIN_ARTICLE_CHARACTERS:
        raise WebArticleError(
            422,
            "article_too_short",
            "The page does not contain enough readable article text for a useful quiz.",
        )

    was_truncated = len(text) > MAX_ARTICLE_CHARACTERS
    if was_truncated:
        text = text[:MAX_ARTICLE_CHARACTERS]
        last_break = max(text.rfind("\n"), text.rfind(" "))
        if last_break >= MAX_ARTICLE_CHARACTERS - 500:
            text = text[:last_break]

    fallback_title = urlsplit(final_url).hostname or "Web article"
    return WebArticleContent(
        url=final_url,
        title=(parser.title or fallback_title)[:120],
        text=text.strip(),
        was_truncated=was_truncated,
    )


class HttpWebArticleRetriever:
    async def fetch(self, value: str) -> WebArticleContent:
        current_url = _normalize_url(value)
        timeout = httpx.Timeout(12.0, connect=5.0)
        headers = {
            "accept": "text/html, text/plain;q=0.8",
            "user-agent": "quizMoi-private-prototype/0.1",
        }
        async with httpx.AsyncClient(
            follow_redirects=False,
            timeout=timeout,
            headers=headers,
            trust_env=False,
        ) as client:
            for redirect_count in range(MAX_REDIRECTS + 1):
                await _ensure_public_destination(current_url)
                try:
                    async with client.stream("GET", current_url) as response:
                        if response.status_code in {301, 302, 303, 307, 308}:
                            if redirect_count == MAX_REDIRECTS:
                                raise WebArticleError(
                                    422,
                                    "article_redirects",
                                    "This article redirects too many times.",
                                )
                            location = response.headers.get("location")
                            if not location:
                                raise WebArticleError(
                                    422,
                                    "article_unavailable",
                                    "The article redirect is incomplete.",
                                )
                            current_url = _normalize_url(
                                urljoin(current_url, location)
                            )
                            continue
                        _validate_response_status(response.status_code)
                        content_type = response.headers.get(
                            "content-type",
                            "",
                        ).casefold()
                        if not (
                            content_type.startswith("text/html")
                            or content_type.startswith("text/plain")
                            or content_type.startswith("application/xhtml+xml")
                        ):
                            raise WebArticleError(
                                415,
                                "unsupported_content",
                                "The URL must point to a readable web article.",
                            )
                        body = await _read_limited_body(response)
                        encoding = response.encoding or "utf-8"
                        decoded = body.decode(encoding, errors="replace")
                        if content_type.startswith("text/plain"):
                            decoded = (
                                "<html><body><main><p>"
                                f"{escape(decoded)}"
                                "</p></main></body></html>"
                            )
                        return extract_web_article(decoded, str(response.url))
                except WebArticleError:
                    raise
                except httpx.TimeoutException as error:
                    raise WebArticleError(
                        504,
                        "article_timeout",
                        "The article website took too long to respond.",
                    ) from error
                except httpx.HTTPError as error:
                    raise WebArticleError(
                        502,
                        "article_unavailable",
                        "quizMoi could not retrieve this article.",
                    ) from error
        raise RuntimeError("Web article redirect handling ended unexpectedly.")


def _normalize_url(value: str) -> str:
    candidate = value.strip()
    try:
        parsed = urlsplit(candidate)
        port = parsed.port
    except ValueError as error:
        raise WebArticleError(400, "invalid_url", "Enter a valid web article URL.") from error
    if parsed.scheme.casefold() not in {"http", "https"} or not parsed.hostname:
        raise WebArticleError(
            400,
            "invalid_url",
            "Enter a complete http:// or https:// web article URL.",
        )
    if parsed.username or parsed.password:
        raise WebArticleError(
            400,
            "unsafe_url",
            "Web article URLs cannot contain a username or password.",
        )
    expected_port = 80 if parsed.scheme.casefold() == "http" else 443
    if port is not None and port != expected_port:
        raise WebArticleError(
            400,
            "unsafe_url",
            "Web article URLs must use the standard HTTP or HTTPS port.",
        )
    hostname = parsed.hostname.casefold()
    if (
        hostname == "localhost"
        or hostname.endswith(".localhost")
        or hostname.endswith(".local")
        or hostname.endswith(".internal")
    ):
        raise WebArticleError(
            400,
            "unsafe_url",
            "Choose a public web article URL.",
        )
    return urlunsplit(
        (
            parsed.scheme.casefold(),
            parsed.netloc,
            parsed.path or "/",
            parsed.query,
            "",
        )
    )


async def _ensure_public_destination(url: str) -> None:
    parsed = urlsplit(url)
    hostname = parsed.hostname
    if hostname is None:
        raise WebArticleError(400, "invalid_url", "Enter a valid article URL.")
    try:
        literal = ipaddress.ip_address(hostname)
        addresses: Sequence[ipaddress.IPv4Address | ipaddress.IPv6Address] = [
            literal
        ]
    except ValueError:
        try:
            resolved = await asyncio.to_thread(
                socket.getaddrinfo,
                hostname,
                parsed.port or (443 if parsed.scheme == "https" else 80),
                type=socket.SOCK_STREAM,
            )
        except OSError as error:
            raise WebArticleError(
                502,
                "article_unavailable",
                "The article website address could not be found.",
            ) from error
        addresses = list(
            {
                ipaddress.ip_address(item[4][0])
                for item in resolved
            }
        )
    if not addresses or any(not address.is_global for address in addresses):
        raise WebArticleError(
            400,
            "unsafe_url",
            "Choose a public web article URL.",
        )


def _validate_response_status(status_code: int) -> None:
    if status_code in {401, 402, 403}:
        raise WebArticleError(
            422,
            "article_paywalled",
            "This article requires permission, a subscription, or sign-in.",
        )
    if status_code == 404:
        raise WebArticleError(404, "article_unavailable", "The article was not found.")
    if status_code == 429:
        raise WebArticleError(
            429,
            "article_rate_limited",
            "The article website is temporarily limiting requests. Try again later.",
        )
    if status_code < 200 or status_code >= 300:
        raise WebArticleError(
            502,
            "article_unavailable",
            "The article website could not provide this page.",
        )


async def _read_limited_body(response: httpx.Response) -> bytes:
    body = bytearray()
    async for chunk in response.aiter_bytes():
        body.extend(chunk)
        if len(body) > MAX_WEB_RESPONSE_BYTES:
            raise WebArticleError(
                413,
                "article_too_large",
                "The web page is too large for this prototype.",
            )
    return bytes(body)
