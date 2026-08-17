# quizMoi Development Roadmap

Audit date: 2026-08-16

## Progress

- [x] Phase 0 — Safe and reproducible development environment (completed 2026-08-16)
- [x] Phase 1 — Stabilize the prototype and define behavior (completed 2026-08-17)
- [ ] Phase 2 — Build the real local learning core
- [ ] Phase 3 — Complete the testing and feedback engine
- [ ] Phase 4 — Content ingestion
- [ ] Phase 5 — AI generation backend
- [ ] Phase 6 — Personalized active recall
- [ ] Phase 7 — Account and synchronization, when needed
- [ ] Phase 8 — Reliability, privacy, and security hardening
- [ ] Phase 9 — Private beta readiness
- [ ] Phase 10 — Public-release decision

Phase 0 completion evidence: the project is stored in a private GitHub repository, the Windows Flutter/Android toolchain and emulator are configured, the application runs on the Android emulator, the setup process is documented in `README.md`, the existing automated test passes, and a clean debug APK build succeeds. Physical-device coverage remains part of private-beta validation.

Phase 1 completion evidence: all analyzer findings have been cleared; quizzes start at zero; unanswered questions cannot advance; restart, exit, and final submission actions require confirmation; previous/next navigation preserves answers and permits corrections; missing results show an honest empty state; unfinished controls explain that they are planned; the version 1 learning loop and demo boundaries are documented; navigation and answer choices expose accessibility state; multiline keyboard input works; all main screens pass narrow-phone checks with enlarged text; 16 provider/widget tests pass; and a clean debug APK build succeeds.

Phase 2 progress: immutable, JSON-serializable learning entities now cover source documents, knowledge bases, concepts, quiz definitions, explanations, attempts, answers, and learner settings. Repository interfaces separate domain code from storage, and SQLite can transactionally save, restore, update, archive-filter, and delete complete quiz definitions and attempts. The app opens the private database during startup; learners can create and edit validated multiple-choice quizzes manually, see saved quizzes on the Dashboard, duplicate/archive/restore/delete them, and launch them through the testing engine. In-progress answers, position, and elapsed time are persisted; app startup offers a Resume Quiz action, while completion, restart, retake, and abandonment update stored attempts consistently. Saved knowledge-base/settings flows, migration away from the remaining sample Dashboard data, and broader database migration coverage are still in progress.

## Product direction

quizMoi will remain privately distributed while it is developed into a reliable Android-first French active-recall application. The first complete product should let one learner import useful material, generate and edit a quiz, complete it, receive trustworthy feedback, and return later to review saved progress.

The roadmap deliberately prioritizes a narrow working learning loop before adding every content type or platform.

## Current baseline

### What exists

- Flutter 3.44.9 / Dart 3.12.2 project with Android, iOS, web, and Windows scaffolding.
- A coherent Crimson Velocity Material 3 theme and reusable UI widgets.
- Four main UI experiences: dashboard, content input, active test, and results.
- Provider-based in-memory quiz state, selection, navigation, elapsed-time display, and score calculation.
- One widget smoke test, which currently passes.

### What is still prototype-only

- Demo quizzes, knowledge bases, user statistics, and most tutor content remain hard-coded; manually created quizzes and their attempts are real local data.
- The entered source text is not used when `Generate Quiz` is pressed.
- File upload, camera scan, URL ingestion, manual quiz creation, review, menu, and several buttons have no behavior.
- Flashcards and Notes are advertised but do not have separate product flows.
- Question models mention fill-in-the-blank and translation, but the testing UI only supports selectable options.
- Local quiz and attempt persistence now exists, but saved knowledge bases, learner settings UI, attempt-history screens, accounts, backend/network clients, and AI services are not yet implemented.
### Verification findings

- `flutter test`: 33 tests pass.
- `flutter analyze`: no issues found.
- Android APK build: `flutter build apk --debug` succeeds.
- Git/GitHub: private repository configured with development branches and pull requests.
- Android still uses a prototype application ID/label, default launcher assets, and debug signing for release builds.

## Target version 1 scope

Version 1 should include:

1. A local learner profile and preferences.
2. Source input from pasted text, PDF, and supported web pages.
3. AI-generated multiple-choice and typed-answer questions.
4. A review/edit step before a generated quiz is saved.
5. Reliable quiz sessions with resume, answer validation, and submission safeguards.
6. Per-answer explanations grounded in the imported source.
7. Saved knowledge bases, quiz history, statistics, weak-concept tracking, and review sessions.
8. Clear offline, loading, empty, retry, and failure experiences.
9. A privately installable signed Android APK with automated quality checks.

Defer until the core loop is proven:

- iOS, web, and desktop production support.
- YouTube transcription, camera/image ingestion, flashcards, and generated notes.
- Social features, leaderboards, subscriptions, and public store release.
- GraphQL unless it solves a demonstrated need; REST is sufficient for the initial service boundary.

## Recommended application structure

Move gradually from the current screen-centered prototype to feature-centered code:

```text
lib/
  app/                 app bootstrap, routing, theme
  core/                errors, networking, storage, utilities
  features/
    dashboard/
    content_ingestion/
    quiz_generation/
    quiz_session/
    results/
    review/
    profile/
  shared/              genuinely reusable widgets
```

Each feature should separate:

- presentation: screens, widgets, and UI state;
- domain: immutable entities and use cases;
- data: local database, API DTOs, repositories, and mappers.

Provider can remain for now. The important change is to stop placing mock data and business rules in a single `QuizProvider`. State-management replacement is not required unless Provider becomes a real constraint.

Never put an LLM provider key in the Android application. AI calls, content fetching, prompt templates, rate limits, and output validation must live behind a backend owned by quizMoi.

## Delivery phases

### Phase 0 — Safe and reproducible development environment

Deliverables:

- Initialize Git, make a baseline commit, and define a simple branch/commit convention.
- Install the Android SDK, platform tools, emulator image, and required build tools.
- Configure `sdk.dir` locally and verify `flutter doctor`.
- Run the app on an emulator and at least one physical Android device.
- Replace the default README with setup, run, test, and private-install instructions.
- Add a `.env.example` or compile-time configuration pattern with no secrets committed.

Exit criteria:

- A fresh checkout can be set up from the README.
- `flutter analyze`, `flutter test`, and `flutter build apk --debug` can all run locally.
- The prototype can be installed and opened on a real Android phone.

### Phase 1 — Stabilize the prototype and define behavior

Deliverables:

- Resolve all analyzer warnings and current Flutter deprecations.
- Write a short product specification for the target version 1 learning loop.
- Hide or label deferred controls so the UI does not promise non-working features.
- Fix timer initialization, unanswered-question handling, restart/exit confirmation, null-result behavior, and navigation consistency.
- Add accessibility semantics, minimum tap targets, text scaling checks, keyboard behavior, and small-screen overflow checks.
- Add dark mode only if it is part of the product specification; otherwise explicitly defer it.

Tests:

- Unit tests for scoring, progress, timer formatting, answer state, and completion rules.
- Widget tests for dashboard, generation validation, quiz navigation, submission, and results.

Exit criteria:

- Analyzer is clean.
- Every visible action either works or clearly communicates its unavailable state.
- The existing demo loop behaves correctly on common Android screen sizes.

### Phase 2 — Build the real local learning core

Deliverables:

- Replace mutable UI models with immutable, serializable domain models.
- Define entities for source documents, knowledge bases, questions, answers, quiz attempts, explanations, concepts, and learner settings.
- Add a local database through a repository interface.
- Persist knowledge bases, generated quizzes, in-progress sessions, attempts, and settings.
- Implement create, edit, duplicate, archive, and delete flows for saved quizzes.
- Implement a manual quiz editor so the app remains useful when AI is unavailable.
- Restore an interrupted quiz after process death or app restart.

Exit criteria:

- A learner can create a quiz, close the app, reopen it, complete the quiz, and see the saved attempt.
- Domain and repository tests cover migrations and round-trip persistence.
- No screen depends on hard-coded production data.

### Phase 3 — Complete the testing and feedback engine

Deliverables:

- Support multiple-choice and typed-answer questions as real distinct types.
- Define normalization rules for accents, punctuation, capitalization, accepted alternatives, and partial credit.
- Add optional time limits, pause/resume behavior, skipped questions, answer review, and final submission confirmation.
- Store question-level timing and answer history for useful diagnostics.
- Generate results only from persisted attempt data.
- Connect weak concepts and recommended review items to actual incorrect answers.

Exit criteria:

- All supported question types can be authored, attempted, scored, reviewed, and restored.
- Scoring is deterministic and exhaustively unit-tested.
- Results, history, dashboard statistics, XP, goals, and streaks all derive from real data.

### Phase 4 — Content ingestion

Implement one source type at a time in this order:

1. Pasted text.
2. Local PDF.
3. Web article URL.

Deliverables:

- File picker, permission handling, size/type validation, and useful error messages.
- Text extraction with page/source references retained for later grounding.
- Server-side URL retrieval with content sanitization and unsupported/paywalled-page handling.
- Chunking, language detection, duplicate detection, and source preview.
- A required preview/confirm step before quiz generation.
- Privacy controls for deleting local and server-side source data.

Exit criteria:

- Each supported source produces normalized text and traceable source segments.
- Malformed, empty, oversized, scanned, protected, and unreachable inputs fail safely.
- Source ingestion has fixture-based tests with representative French content.

### Phase 5 — AI generation backend

Deliverables:

- Choose and document the backend, database, authentication, storage, and LLM-provider boundaries in architecture decision records.
- Create authenticated endpoints for ingestion, generation, explanation, and job status.
- Use versioned prompts and strict structured-output schemas.
- Validate every generated question: correct answer exists, distractors are unique, language/level match, and source evidence is present.
- Add background jobs, retries, cancellation, timeout handling, quotas, observability, and cost tracking.
- Cache safe repeat work and prevent duplicate generation requests.
- Add a generation review screen where the learner can edit or reject weak questions before saving.
- Keep explanations grounded with source excerpts/references and disclose when confidence is low.

Exit criteria:

- Pasted French content can produce a validated quiz end to end without secrets in the app.
- Invalid model output never reaches the learner as a valid quiz.
- A small, reviewed evaluation set measures factual grounding, answer correctness, CEFR fit, ambiguity, and distractor quality.
- Cost and latency are measured per generation request.

### Phase 6 — Personalized active recall

Deliverables:

- Define a review scheduling algorithm and store per-concept/per-question mastery.
- Build a daily review queue based on errors, recency, confidence, and repeated performance.
- Calculate XP, streaks, daily goals, and average accuracy from documented rules.
- Add concept tags and grammar/vocabulary categories.
- Make dashboard recommendations actionable and explain why an item is recommended.
- Add notification preferences; request notification permission only when the learner enables reminders.

Exit criteria:

- Completing attempts changes the next review queue predictably.
- Statistics can be recomputed from attempt history.
- Time-zone changes, missed days, and device clock edge cases are tested.

### Phase 7 — Account and synchronization (only when needed)

Start version 1 as local-first if the app is used by one private tester. Add accounts when multi-device use, backup, or a wider test group justifies them.

Deliverables when activated:

- Sign-in, sign-out, account deletion, token refresh, and secure credential storage.
- Per-user authorization on every backend resource.
- Sync conflict policy, offline queue, retry behavior, and backup/restore.
- Data export and deletion controls.

Exit criteria:

- One user cannot access another user's sources, quizzes, attempts, or generated content.
- Offline changes synchronize without silent data loss.
- Account deletion is complete and testable.

### Phase 8 — Reliability, privacy, and security hardening

Deliverables:

- Threat-model uploads, remote URLs, prompt injection, malicious documents, leaked secrets, and broken authorization.
- Apply transport security, secure local secret storage, least-privilege permissions, upload limits, and server-side content validation.
- Add crash reporting and privacy-aware structured logs with no source text or answers by default.
- Define retention, deletion, backup, and incident-response policies.
- Add network-loss, slow-network, backend-failure, rate-limit, and corrupted-database tests.
- Audit third-party licenses and content-processing terms.

Exit criteria:

- No credentials or private study content appear in logs or source control.
- Critical flows recover from expected failures without losing learner work.
- Security and privacy checklist has no unresolved high-severity items.

### Phase 9 — Private beta readiness

Deliverables:

- Final application ID, app name, launcher icon, adaptive icon, splash screen, and versioning policy.
- Separate development/staging/production configurations and backend environments.
- Private release signing with keys stored outside the repository and backed up securely.
- CI checks for formatting, analysis, unit/widget tests, and Android builds.
- Integration tests for the complete source-to-review journey.
- Performance checks for launch, scrolling, large PDFs, generation polling, memory use, and battery use.
- Accessibility and French-character/input testing on representative devices.
- Produce signed APKs for a small named tester group and maintain a feedback/defect log.

Exit criteria:

- A signed private build installs, upgrades without data loss, and completes the version 1 learning loop on the supported Android versions/devices.
- No open critical/high defects; medium defects have explicit decisions.
- Backup, rollback, and tester update instructions are rehearsed.

### Phase 10 — Public-release decision

This is a decision gate, not the current goal. Consider store preparation only after private beta evidence shows that quiz quality, retention value, reliability, privacy, and operating cost meet agreed targets.

## Suggested milestone sequence

| Milestone | Phases | Outcome |
| --- | --- | --- |
| M0: Installable baseline | 0–1 | Clean, reproducible Android prototype |
| M1: Useful without AI | 2–3 | Persistent manual quiz and review product |
| M2: Source pipeline | 4 | Text/PDF/web content becomes normalized source material |
| M3: AI learning loop | 5 | Grounded generation and explanations through a secure backend |
| M4: Retention product | 6 | Personalized review and real learner statistics |
| M5: Private beta | 7–9 as needed | Secure, signed, testable build for private users |

## Quality gates for every feature

A feature is done only when:

- behavior and edge cases are written down;
- loading, empty, error, retry, and offline states are handled where relevant;
- business logic has unit tests and critical UI behavior has widget/integration coverage;
- analyzer and tests pass;
- accessibility and small-screen behavior are checked;
- persistence and migration impact are considered;
- privacy, security, logging, and cost impact are considered;
- documentation is updated.

## Immediate working backlog

Execute these tasks next, in order:

1. Initialize Git and preserve the audited prototype as the baseline commit.
2. Install/configure the Android SDK and prove debug APK installation on a device.
3. Replace the README and document exact setup commands.
4. Clear the 68 analyzer findings.
5. Fix timer, submission, unanswered-question, restart/exit, and empty-results behavior.
6. Add meaningful unit and widget tests around the corrected quiz loop.
7. Write the version 1 product behavior specification and hide deferred UI promises.
8. Define immutable models and repository interfaces.
9. Add local persistence and manual quiz creation.
10. Start pasted-text ingestion, then design the secure AI backend contract.

This order creates a stable, recoverable foundation and a useful local product before the costlier ingestion and AI layers are introduced.
