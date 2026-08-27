from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class ApiModel(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        extra="forbid",
        str_strip_whitespace=True,
    )


class GenerateQuizRequest(ApiModel):
    schema_version: Literal[1] = Field(alias="schemaVersion")
    request_id: str = Field(alias="requestId", min_length=8, max_length=128)
    source_title: str = Field(alias="sourceTitle", min_length=1, max_length=120)
    source_text: str = Field(alias="sourceText", min_length=200, max_length=12000)
    cefr_level: Literal["A1", "A2", "B1", "B2", "C1", "C2"] = Field(
        alias="cefrLevel"
    )
    difficulty: Literal["easy", "medium", "hard"]
    question_count: int = Field(alias="questionCount", ge=5, le=15)
    question_types: list[Literal["multipleChoice"]] = Field(
        alias="questionTypes", min_length=1, max_length=1
    )

    @field_validator("question_types")
    @classmethod
    def only_one_multiple_choice_type(cls, value: list[str]) -> list[str]:
        if value != ["multipleChoice"]:
            raise ValueError("Phase 3 supports multiple-choice questions only.")
        return value


class GeneratePdfQuizRequest(ApiModel):
    schema_version: Literal[1] = Field(alias="schemaVersion")
    request_id: str = Field(alias="requestId", min_length=8, max_length=128)
    source_title: str = Field(alias="sourceTitle", min_length=1, max_length=120)
    cefr_level: Literal["A1", "A2", "B1", "B2", "C1", "C2"] = Field(
        alias="cefrLevel"
    )
    difficulty: Literal["easy", "medium", "hard"]
    question_count: int = Field(alias="questionCount", ge=5, le=15)
    question_types: list[Literal["multipleChoice"]] = Field(
        alias="questionTypes", min_length=1, max_length=1
    )

    @field_validator("question_types")
    @classmethod
    def only_one_multiple_choice_type(cls, value: list[str]) -> list[str]:
        if value != ["multipleChoice"]:
            raise ValueError("Phase 4 currently supports multiple-choice questions only.")
        return value


class GeneratedOption(ApiModel):
    id: Literal["a", "b", "c", "d"]
    text: str = Field(min_length=1, max_length=300)


class GeneratedConcept(ApiModel):
    name: str = Field(min_length=1, max_length=100)
    category: str = Field(min_length=1, max_length=50)


class GeneratedQuestion(ApiModel):
    prompt: str = Field(min_length=1, max_length=600)
    options: list[GeneratedOption] = Field(min_length=4, max_length=4)
    correct_option_id: Literal["a", "b", "c", "d"] = Field(
        alias="correctOptionId"
    )
    explanation: str = Field(min_length=1, max_length=1200)
    source_excerpt: str = Field(alias="sourceExcerpt", min_length=1, max_length=1000)
    concepts: list[GeneratedConcept] = Field(min_length=1, max_length=3)

    @model_validator(mode="after")
    def validate_options(self) -> "GeneratedQuestion":
        option_ids = [option.id for option in self.options]
        option_text = [option.text.casefold() for option in self.options]
        if set(option_ids) != {"a", "b", "c", "d"}:
            raise ValueError("Options must use ids a, b, c, and d exactly once.")
        if len(set(option_text)) != 4:
            raise ValueError("Answer option text must be unique.")
        if self.correct_option_id not in option_ids:
            raise ValueError("The correct answer must match an option id.")
        return self


class GeneratedQuizPayload(ApiModel):
    title: str = Field(min_length=1, max_length=120)
    questions: list[GeneratedQuestion] = Field(min_length=5, max_length=15)


class GenerateQuizResponse(GeneratedQuizPayload):
    schema_version: Literal[1] = Field(alias="schemaVersion")
    request_id: str = Field(alias="requestId", min_length=1)


class HealthResponse(ApiModel):
    status: Literal["ok"]
    model: str
    configured: bool
