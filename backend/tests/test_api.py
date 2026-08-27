from fastapi.testclient import TestClient

from app.main import app, get_generator
from app.schemas import GeneratePdfQuizRequest, GenerateQuizRequest, GeneratedQuizPayload
from app.service import InvalidGenerationError, validate_generated_quiz


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
    async def generate(self, _request: GenerateQuizRequest) -> GeneratedQuizPayload:
        return _payload()

    async def generate_pdf(
        self,
        _request: GeneratePdfQuizRequest,
        _pdf_bytes: bytes,
        _file_name: str,
    ) -> GeneratedQuizPayload:
        return _payload()


def test_health_does_not_require_an_api_key() -> None:
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert "configured" in response.json()


def test_generate_returns_the_versioned_quiz_contract() -> None:
    app.dependency_overrides[get_generator] = lambda: FakeGenerator()
    client = TestClient(app)
    try:
        response = client.post(
            "/v1/quizzes/generate",
            json={
                "schemaVersion": 1,
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
    assert body["requestId"]
    assert len(body["questions"]) == 5
    assert body["questions"][0]["correctOptionId"] == "a"


def test_invalid_source_is_rejected_before_generation() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/quizzes/generate",
        json={
            "schemaVersion": 1,
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
    assert len(response.json()["questions"]) == 5


def test_pdf_route_rejects_content_without_a_pdf_signature() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/quizzes/generate-pdf",
        data={
            "schemaVersion": "1",
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
