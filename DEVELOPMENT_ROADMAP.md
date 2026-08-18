# quizMoi Build-First Development Roadmap

Last restructured: 2026-08-17

## Progress

- [x] Phase 0 — Safe and reproducible development environment (completed 2026-08-16)
- [x] Phase 1 — Stabilize the prototype and define behavior (completed 2026-08-17)
- [x] Phase 2 — Build the real local learning core (completed 2026-08-17)
- [x] Phase 3 — Complete the AI learning prototype (completed 2026-08-17)
- [ ] Phase 4 — Complete the Version 1 feature breadth
- [ ] Phase 5 — Self-use alpha
- [ ] Phase 6 — Hosted private beta
- [ ] Phase 7 — Reliability and polish
- [ ] Phase 8 — Conditional accounts and public-release decision

Phase 0 completion evidence: the project is in a private GitHub repository, the Flutter/Android toolchain and emulator are configured, setup is documented, the app runs on Android, tests pass, and a debug APK builds.

Phase 1 completion evidence: analyzer findings were cleared; quiz navigation, confirmation, accessibility, small-screen behavior, empty states, and demo boundaries were stabilized and tested.

Phase 2 completion evidence: SQLite-backed repositories persist knowledge bases, manual quizzes, in-progress sessions, attempts, learner settings, real history, accuracy, goals, and streaks. Schema version 2 upgrades version-1 data without loss, restart behavior is covered end to end, and 48 Flutter tests pass.

Phase 3 completion evidence: a real Android-emulator test sent pasted French text through the local FastAPI backend and OpenAI, returned ten structured multiple-choice questions, saved the generated source and quiz, completed and scored the attempt, and reflected the result on the dashboard. Automated backend, Flutter, persistence, restart, analyzer, and debug-APK checks pass. UX and metric findings discovered during self-use remain tracked in `DEFECT_LOG.md` and do not invalidate the working source-to-feedback integration.

## Build-first method

quizMoi keeps the complete Version 1 scope, but work is now ordered by usable learner journeys instead of technical layers. First create a narrow source-to-feedback loop, then broaden it, use it, host it privately, and finally harden and polish it.

The first working prototype is:

1. Paste French study text.
2. Preview and confirm the source.
3. Generate ten grounded multiple-choice questions through a local quizMoi backend.
4. Review, edit, remove, reorder, or regenerate the draft.
5. Save the source and quiz locally, optionally in a knowledge base.
6. Complete the persistent quiz session.
7. See grounded explanations, concepts, history, and real progress after restart.

Cosmetic and uncommon edge-case defects may be logged for later. Secret exposure, data loss, incorrect scoring, broken tests, and an unbuildable APK are never acceptable shortcuts.

## Target Version 1

Version 1 retains:

- local learner settings and progress;
- pasted text, PDFs, camera-captured study images, and supported web-article sources;
- AI-generated multiple-choice and typed-answer questions;
- generated-question review and editing;
- persistent sessions, attempts, feedback, knowledge bases, and history;
- grounded explanations, weak concepts, and a daily review queue;
- clear loading, retry, offline, and failure states;
- a privately signed Android APK with automated checks.

Still deferred: production iOS/web/desktop support, YouTube transcription, flashcards, notes, social features, subscriptions, and public-store work.

## Phase 3 — Complete the AI learning prototype

### 3.1 Roadmap and service boundary

- Keep Phases 0–2 intact and document this build-first sequence.
- Add a Python FastAPI service under `backend/`.
- Provide `GET /health` and `POST /v1/quizzes/generate`.
- Keep `OPENAI_API_KEY` and `OPENAI_MODEL` in backend environment variables only.
- Use the OpenAI Responses API with a strict structured-output schema.
- Default to `gpt-5.6-luna`, with the model configurable without an app rebuild.
- Accept 200–12,000 source characters, CEFR level, difficulty, and 5–15 multiple-choice questions.

### 3.2 Pasted-text generation

- Turn the demo field into validated pasted-text input.
- Show a required source preview before spending an AI request.
- Preserve input across loading, timeout, unavailable-backend, invalid-output, and retry states.
- Keep **Try Demo Quiz** as an explicit offline secondary action.

### 3.3 Review and local save

- Map the backend response through a provider-independent generation gateway.
- Review and edit generated questions before saving.
- Preserve explanations, source excerpts, and concept tags during edits.
- Save the source, generated quiz, and optional knowledge-base relationship locally.
- Launch the saved quiz through the existing persistent session engine.

### 3.4 Grounded results

- Render results from the completed persistent attempt.
- Show generated explanations and source excerpts for incorrect answers.
- Derive concept recommendations from the actual incorrect questions.
- Refresh saved quizzes, history, dashboard progress, goals, and streaks.

Exit criteria: pasted French text produces an editable ten-question MCQ quiz; the learner can save, complete, review, and reopen it; grounded feedback and all learning data survive restart; no secret is present in Flutter or Git.

## Phase 4 — Complete the Version 1 feature breadth

### Additional sources

- [x] Add Android PDF selection, filename/size preview, 10 MB validation, and safe unsupported/oversized errors.
- [x] Send confirmed PDFs through FastAPI to the OpenAI Responses API as direct file input, keeping the API key out of Flutter.
- [x] Validate the structured quiz response and save PDF metadata, questions, explanations, concepts, and attempts through the existing local learning core.
- [x] Manually accept a real PDF-to-quiz OpenAI request on the emulator: generate ten questions, save the quiz, and complete the attempt. The first response was interrupted by an emulator network switch and is tracked as `QM-004`; one retry completed the journey.
- [x] Confirm the generated PDF quiz and completed attempt survive closing the app, clearing recent apps, and reopening quizMoi.
- [ ] Add on-demand Android camera permission, capture/retake, image preview, size/orientation checks, and explicit confirmation before upload.
- [ ] Send a confirmed study image through FastAPI as OpenAI image input and reuse the same structured ten-question generation, save, testing, feedback, and persistence flow.
- Add backend web-article retrieval, sanitization, and unsupported/paywalled-page handling.
- Add chunking, language checks, duplicate detection, references, and source deletion.

### Quiz types and controls

- Add typed-answer authoring, generation, input, restoration, and deterministic scoring.
- Document normalization for whitespace, capitalization, punctuation, accents, alternatives, and partial credit.
- Add skip/review, pause/resume, optional limits, question timing, and answer history.
- Make difficulty, count, and type controls interactive.
- Add individual-question regeneration.

### Personalized recall

- Build weak-concept tracking, documented mastery rules, and a daily review queue.
- Make recommendations actionable and explain their reason.
- Request notification permission only after reminders are enabled.

Exit criteria: text, PDF, camera image, and supported URL sources work; MCQ and typed-answer quizzes can be generated and completed; review recommendations derive from real performance.

## Phase 5 — Self-use alpha

- Use the app on the emulator and owner’s Android phone with the backend running locally.
- Maintain the repository's [defect and improvement log](DEFECT_LOG.md).
- Fix crashes, data loss, broken navigation, misleading results, and unusable AI output immediately.
- Iterate on the complete journey before expanding low-value features.

## Phase 6 — Hosted private beta

- Containerize FastAPI and deploy it to Google Cloud Run.
- Store secrets in cloud secret management.
- Use Firebase anonymous identity for per-installation access and quotas.
- Add throttling, daily limits, cost tracking, and privacy-aware logs.
- Separate development and private-beta configuration.
- Finalize Android identity, icons, versioning, signing, and CI.
- Publish signed APKs through private GitHub Releases and verify upgrades without data loss.

## Phase 7 — Reliability and polish

- Add safe retries, cancellation, background jobs, deduplication, caching, and offline recovery.
- Harden URL/PDF/image processing, prompt-injection defenses, authorization, deletion, secrets, and database recovery.
- Expand quiz-quality evaluation for grounding, correctness, CEFR fit, ambiguity, distractors, and explanations.
- Complete accessibility, large-text, French-input, layout, performance, battery, and device testing.
- Polish onboarding, design consistency, animation, empty states, errors, and navigation.
- Resolve all critical/high defects and explicitly decide remaining medium defects.

## Phase 8 — Conditional accounts and release decision

- Add visible accounts, sync, backup/restore, export, conflict handling, and account deletion only when wider testing proves the need.
- Consider Play Store preparation only after private evidence validates usefulness, reliability, privacy, quiz quality, and operating cost.

## Previous-deliverable mapping

| Previous phase | New location |
| --- | --- |
| Testing and feedback | MCQ feedback in Phase 3; typed/session breadth in Phase 4; exhaustive cases in Phase 7 |
| Content ingestion | Pasted text in Phase 3; PDF/camera image/URL in Phase 4; hardening in Phase 7 |
| AI backend | Local generation in Phase 3; hosting in Phase 6; jobs/evals/observability in Phase 7 |
| Personalization | Core review queue in Phase 4; clock/failure edges in Phase 7 |
| Accounts and sync | Conditional Phase 8 |
| Security and reliability | Minimum online security in Phase 6; comprehensive hardening in Phase 7 |
| Private beta | Phase 6 |
| Public-release decision | Phase 8 |

## Essential gate for every checkpoint

- Format and static analysis pass.
- Existing tests stay green and new business logic has focused tests.
- Critical UI behavior has widget or integration coverage.
- A debug APK builds.
- The checkpoint happy path is manually checked on Android.
- Secrets and private source text never enter source control or logs.

## Immediate backlog

1. Prevent a completed AI result from being lost or charged twice after a client connection interruption (`QM-004`).
2. Add supported web-article ingestion through the backend.
3. Add the planned camera-image source journey without implementing it as part of the current PDF checkpoint.
4. Add typed-answer questions and deterministic normalization/scoring.
5. Add the remaining session controls, generation settings, weak-concept mastery, and daily review queue.
