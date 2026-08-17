# Architecture Decision 0001: Local persistence

Date: 2026-08-17
Status: Accepted for Phase 2

## Context

quizMoi needs private, durable storage for structured learning data. The first
supported product is Android-first and local-first, but storage code must remain
testable and replaceable without changing widgets or domain rules.

## Decision

Use SQLite through `sqflite` for the on-device database and expose storage
through repository interfaces. Use `sqflite_common_ffi` only in development
tests to run the same SQL against an in-memory database.

The initial schema is normalized around source documents, knowledge bases,
quizzes, questions, options, explanations, concepts, attempts, answers, and
learner settings. Schema changes must increment `QuizDatabase.schemaVersion`
and include migration coverage before release.

## Why

- SQLite is supported by Flutter's official persistence guidance for structured
  local data.
- Transactions prevent partially saved quiz aggregates.
- Foreign keys and cascading deletes make ownership rules explicit.
- Repository interfaces keep Flutter screens independent from SQL and allow
  fast in-memory fakes in widget tests.
- A schema version creates an explicit path for future migrations.

## Consequences

- Database initialization is asynchronous and must be handled during app
  startup before persistent screens are connected.
- Domain-to-row mapping is maintained by the data layer.
- Editing questions after completed attempts exist will need a history-safe
  policy before attempt persistence is connected.
- The current prototype models remain temporarily in place while screens are
  migrated feature by feature.
