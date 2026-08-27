from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from app.main import (
    app,
    get_generation_recovery_store,
    get_generator,
    get_web_article_retriever,
)
from app.schemas import GeneratePdfQuizRequest, GenerateQuizRequest, GeneratedQuizPayload
from app.service import InvalidGenerationError, validate_generated_quiz
from app.web_article import WebArticleContent, WebArticleError


SOURCE = ("Marie prend le train chaque matin pour aller à son travail. " * 8).strip()


def _payload(count: int = 5) -> GeneratedQuizPayload:
    return GeneratedQuizPayload.model_validate(
        {
            "title": "Le trajet de Marie",
            "questions": [
                {
                    "prompt": f"Question {index + 1}: comment Marie voyage-t-elle ?",
                    "options": [
                        {"id": "a", "text": "En train"},
                        {"id": "b", "text": "En avion"},
                        {"id": "c", "text": "À vélo"},
                        {"id": "d", "text": "À pied"},
                    ],
                    "correctOptionId": "a",
                    "explanation": "Le texte dit que Marie prend le train.",
                    "sourceExcerpt": "Marie prend le train chaque matin",
                    "concepts": [
                        {"name": "Les transports", "category": "vocabulary"}
                    ],
                }
                for index in range(count)
            ],
        }
    )


class FakeGenerator:
    def __init__(self) -> None:
        self.text_call_count = 0
        self.pdf_call_count = 0

    async def generate(self, _request: GenerateQuizRequest) -> GeneratedQuizPayload:
        self.text_call_count += 1
        return _payload()

    async def generate_pdf(
        self,
        _request: GeneratePdfQuizRequest,
        _pdf_bytes: bytes,
        _file_name: str,
    ) -> GeneratedQuizPayload:
        self.pdf_call_count += 1
        return _payload()


class FakeWebArticleRetriever:
    def __init__(self, *, error: WebArticleError | None = None) -> None:
        self.error = error
        self.urls: list[str] = []

    async def fetch(self, url: str) -> WebArticleContent:
        self.urls.append(url)
        if self.error is not None:
            raise self.error
        return WebArticleContent(
            url="https://example.com/fr/article",
            title="La bibliothèque du quartier",
            text=SOURCE,
            was_truncated=False,
        )

@pytest.fixture(autouse=True)
def reset_app_dependencies() -> Iterator[None]:
    app.dependency_overrides.clear()
    get_generation_recovery_store.cache_clear()
    get_web_article_retriever.cache_clear()
    yield
    app.dependency_overrides.clear()
    get_generation_recovery_store.cache_clear()
    get_web_article_retriever.cache_clear()


def test_health_does_not_require_an_api_key() -> None:
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert "configured" in response.json()


def test_web_article_preview_returns_clean_source_contract() -> None:
    retriever = FakeWebArticleRetriever()
    app.dependency_overrides[get_web_article_retriever] = lambda: retriever

    with TestClient(app) as client:
        response = client.post(
            "/v1/sources/web/preview",
            json={
                "schemaVersion": 1,
                "url": "https://example.com/fr/article",
            },
        )

    assert response.status_code == 200
    assert retriever.urls == ["https://example.com/fr/article"]
    assert response.json() == {
        "schemaVersion": 1,
        "url": "https://example.com/fr/article",
        "title": "La bibliothèque du quartier",
        "text": SOURCE,
        "characterCount": len(SOURCE),
        "wasTruncated": False,
    }


def test_web_article_preview_preserves_stable_fetch_error() -> None:
    retriever = FakeWebArticleRetriever(
        error=WebArticleError(
            422,
            "article_paywalled",
            "This article requires a subscription.",
        )
    )
    app.dependency_overrides[get_web_article_retriever] = lambda: retriever

    with TestClient(app) as client:
        response = client.post(
            "/v1/sources/web/preview",
            json={"schemaVersion": 1, "url": "https://example.com/paywall"},
        )

    assert response.status_code == 422
    assert response.json()["detail"] == {
        "code": "article_paywalled",
        "message": "This article requires a subscription.",
    }


def test_generate_returns_the_versioned_quiz_contract() -> None:
    app.dependency_overrides[get_generator] = lambda: FakeGenerator()
    client = TestClient(app)
    try:
        response = client.post(
            "/v1/quizzes/generate",
            json={
                "schemaVersion": 1,
                "requestId": "generation-text-contract",
                "sourceTitle": "Le trajet de Marie",
                "sourceText": SOURCE,
                "cefrLevel": "B1",
                "difficulty": "medium",
                "questionCount": 5,
                "questionTypes": ["multipleChoice"],
            },
        )
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    body = response.json()
    assert body["schemaVersion"] == 1
    assert body["requestId"] == "generation-text-contract"
    assert len(body["questions"]) == 5
    assert body["questions"][0]["correctOptionId"] == "a"


def test_invalid_source_is_rejected_before_generation() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/quizzes/generate",
        json={
            "schemaVersion": 1,
            "requestId": "generation-invalid-source",
            "sourceTitle": "Too short",
            "sourceText": "Bonjour",
            "cefrLevel": "B1",
            "difficulty": "medium",
            "questionCount": 5,
            "questionTypes": ["multipleChoice"],
        },
    )
    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "invalid_request"


def test_pdf_is_passed_to_generation_and_returns_the_quiz_contract() -> None:
    app.dependency_overrides[get_generator] = lambda: FakeGenerator()
    client = TestClient(app)
    try:
        response = client.post(
            "/v1/quizzes/generate-pdf",
            data={
                "schemaVersion": "1",
                "requestId": "generation-pdf-contract",
                "sourceTitle": "French lesson",
                "cefrLevel": "B1",
                "difficulty": "medium",
                "questionCount": "5",
                "questionTypes": "multipleChoice",
            },
            files={
                "file": (
                    "lesson.pdf",
                    b"%PDF-1.4\nquizMoi test document",
                    "application/pdf",
                )
            },
        )
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()["requestId"] == "generation-pdf-contract"
    assert len(response.json()["questions"]) == 5


def test_pdf_route_rejects_content_without_a_pdf_signature() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/quizzes/generate-pdf",
        data={
            "schemaVersion": "1",
            "requestId": "generation-invalid-pdf",
            "sourceTitle": "Not a PDF",
            "cefrLevel": "B1",
            "difficulty": "medium",
            "questionCount": "5",
            "questionTypes": "multipleChoice",
        },
        files={"file": ("lesson.pdf", b"plain text", "application/pdf")},
    )

    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "invalid_pdf"


def test_grounding_rejects_an_excerpt_not_in_the_source() -> None:
    request = GenerateQuizRequest.model_validate(
        {
            "schemaVersion": 1,
            "requestId": "generation-grounding-test",
            "sourceTitle": "Le trajet de Marie",
            "sourceText": SOURCE,
            "cefrLevel": "B1",
            "difficulty": "medium",
            "questionCount": 5,
            "questionTypes": ["multipleChoice"],
        }
    )
    payload = _payload()
    changed = payload.model_copy(deep=True)
    changed.questions[0].source_excerpt = "Cette phrase n'existe pas."

    try:
        validate_generated_quiz(request, changed)
    except InvalidGenerationError as error:
        assert "source excerpt" in str(error)
    else:
        raise AssertionError("Ungrounded output should be rejected.")


def test_repeated_text_request_id_reuses_the_completed_result() -> None:
    generator = FakeGenerator()
    app.dependency_overrides[get_generator] = lambda: generator
    request_body = {
        "schemaVersion": 1,
        "requestId": "generation-text-recovery",
        "sourceTitle": "Le trajet de Marie",
        "sourceText": SOURCE,
        "cefrLevel": "B1",
        "difficulty": "medium",
        "questionCount": 5,
        "questionTypes": ["multipleChoice"],
    }

    with TestClient(app) as client:
        first = client.post("/v1/quizzes/generate", json=request_body)
        recovered = client.post("/v1/quizzes/generate", json=request_body)

    assert first.status_code == 200
    assert recovered.status_code == 200
    assert recovered.json() == first.json()
    assert generator.text_call_count == 1


def test_repeated_pdf_request_id_reuses_the_completed_result() -> None:
    generator = FakeGenerator()
    app.dependency_overrides[get_generator] = lambda: generator
    form = {
        "schemaVersion": "1",
        "requestId": "generation-pdf-recovery",
        "sourceTitle": "French lesson",
        "cefrLevel": "B1",
        "difficulty": "medium",
        "questionCount": "5",
        "questionTypes": "multipleChoice",
    }
    pdf_file = {
        "file": (
            "lesson.pdf",
            b"%PDF-1.4\nquizMoi recovery test",
            "application/pdf",
        )
    }

    with TestClient(app) as client:
        first = client.post(
            "/v1/quizzes/generate-pdf", data=form, files=pdf_file
        )
        recovered = client.post(
            "/v1/quizzes/generate-pdf", data=form, files=pdf_file
        )

    assert first.status_code == 200
    assert recovered.status_code == 200
    assert recovered.json() == first.json()
    assert generator.pdf_call_count == 1


def test_reusing_request_id_for_different_content_is_rejected() -> None:
    generator = FakeGenerator()
    app.dependency_overrides[get_generator] = lambda: generator
    original = {
        "schemaVersion": 1,
        "requestId": "generation-conflict-test",
        "sourceTitle": "Le trajet de Marie",
        "sourceText": SOURCE,
        "cefrLevel": "B1",
        "difficulty": "medium",
        "questionCount": 5,
        "questionTypes": ["multipleChoice"],
    }
    changed = dict(original)
    changed["sourceText"] = ("Paul prend le bus chaque matin. " * 12).strip()

    with TestClient(app) as client:
        first = client.post("/v1/quizzes/generate", json=original)
        conflict = client.post("/v1/quizzes/generate", json=changed)

    assert first.status_code == 200
    assert conflict.status_code == 409
    assert conflict.json()["detail"]["code"] == "idempotency_conflict"
    assert generator.text_call_count == 1
