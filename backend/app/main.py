import os
from functools import lru_cache
from uuid import uuid4

from fastapi import Depends, FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import ValidationError

from .schemas import (
    GeneratePdfQuizRequest,
    GenerateQuizRequest,
    GenerateQuizResponse,
    HealthResponse,
)
from .service import (
    BackendNotConfiguredError,
    GenerationProviderError,
    GenerationQuotaError,
    GenerationTimeoutError,
    InvalidGenerationError,
    OpenAIQuizGenerator,
    QuizGenerator,
)

app = FastAPI(title="quizMoi generation backend", version="0.1.0")
MAX_PDF_BYTES = 10 * 1024 * 1024


@lru_cache
def get_generator() -> QuizGenerator:
    return OpenAIQuizGenerator()


def _error(status: int, code: str, message: str) -> HTTPException:
    return HTTPException(status_code=status, detail={"code": code, "message": message})


@app.exception_handler(RequestValidationError)
async def request_validation_error(
    _request: Request,
    _error_value: RequestValidationError,
) -> JSONResponse:
    return JSONResponse(
        status_code=400,
        content={
            "detail": {
                "code": "invalid_request",
                "message": "Check the source text and quiz settings, then try again.",
            }
        },
    )


@app.get("/health", response_model=HealthResponse, response_model_by_alias=True)
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        model=os.getenv("OPENAI_MODEL", "gpt-5.6-luna"),
        configured=bool(os.getenv("OPENAI_API_KEY")),
    )


@app.post(
    "/v1/quizzes/generate",
    response_model=GenerateQuizResponse,
    response_model_by_alias=True,
)
async def generate_quiz(
    request: GenerateQuizRequest,
    generator: QuizGenerator = Depends(get_generator),
) -> GenerateQuizResponse:
    try:
        generated = await generator.generate(request)
    except BackendNotConfiguredError as error:
        raise _error(503, "backend_not_configured", str(error)) from error
    except GenerationTimeoutError as error:
        raise _error(504, "generation_timeout", str(error)) from error
    except GenerationQuotaError as error:
        raise _error(429, "generation_quota", str(error)) from error
    except InvalidGenerationError as error:
        raise _error(422, "invalid_generation", str(error)) from error
    except GenerationProviderError as error:
        raise _error(502, "generation_provider", str(error)) from error

    return GenerateQuizResponse(
        schema_version=1,
        request_id=str(uuid4()),
        title=generated.title,
        questions=generated.questions,
    )


@app.post(
    "/v1/quizzes/generate-pdf",
    response_model=GenerateQuizResponse,
    response_model_by_alias=True,
)
async def generate_quiz_from_pdf(
    file: UploadFile = File(...),
    schema_version: int = Form(alias="schemaVersion"),
    source_title: str = Form(alias="sourceTitle"),
    cefr_level: str = Form(alias="cefrLevel"),
    difficulty: str = Form(...),
    question_count: int = Form(alias="questionCount"),
    question_types: str = Form(alias="questionTypes"),
    generator: QuizGenerator = Depends(get_generator),
) -> GenerateQuizResponse:
    try:
        request = GeneratePdfQuizRequest.model_validate(
            {
                "schemaVersion": schema_version,
                "sourceTitle": source_title,
                "cefrLevel": cefr_level,
                "difficulty": difficulty,
                "questionCount": question_count,
                "questionTypes": [question_types],
            }
        )
    except ValidationError as error:
        raise _error(
            400,
            "invalid_request",
            "Check the PDF and quiz settings, then try again.",
        ) from error

    file_name = file.filename or "Imported PDF.pdf"
    if not file_name.lower().endswith(".pdf"):
        raise _error(400, "invalid_pdf", "Choose a PDF file.")
    pdf_bytes = await file.read(MAX_PDF_BYTES + 1)
    await file.close()
    if len(pdf_bytes) > MAX_PDF_BYTES:
        raise _error(413, "pdf_too_large", "The PDF must be 10 MB or smaller.")
    if not pdf_bytes.startswith(b"%PDF-"):
        raise _error(400, "invalid_pdf", "The selected file is not a readable PDF.")

    try:
        generated = await generator.generate_pdf(request, pdf_bytes, file_name)
    except BackendNotConfiguredError as error:
        raise _error(503, "backend_not_configured", str(error)) from error
    except GenerationTimeoutError as error:
        raise _error(504, "generation_timeout", str(error)) from error
    except GenerationQuotaError as error:
        raise _error(429, "generation_quota", str(error)) from error
    except InvalidGenerationError as error:
        raise _error(422, "invalid_generation", str(error)) from error
    except GenerationProviderError as error:
        raise _error(502, "generation_provider", str(error)) from error

    return GenerateQuizResponse(
        schema_version=1,
        request_id=str(uuid4()),
        title=generated.title,
        questions=generated.questions,
    )
