import os
from functools import lru_cache
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from .schemas import GenerateQuizRequest, GenerateQuizResponse, HealthResponse
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
