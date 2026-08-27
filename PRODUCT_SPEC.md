# quizMoi Version 1 Product Specification

Status: Build-first private development
Last updated: 2026-08-17

## Product promise

quizMoi helps a French learner turn their own study material into active-recall practice, understand mistakes, and return to weak concepts without manually creating every question.

Version 1 succeeds when one learner can import material, review an automatically generated quiz, complete it, understand grounded results, and later resume review without losing work.

## Primary learner

The first learner is the owner: an independent beginner-to-intermediate French learner who is also learning app development. Interface copy must explain actions, limitations, loading states, and errors in plain language.

## Build-first delivery contract

The product will be created in complete vertical slices and polished afterward:

1. The first prototype supports pasted text and AI-generated multiple-choice quizzes.
2. The next breadth pass adds PDF, camera-captured study images, web articles, typed answers, session controls, and personalized review.
3. Self-use comes before hosting for other testers.
4. Private-beta hosting, security, signing, and distribution come before comprehensive polish.
5. Public-release work remains a later evidence-based decision.

No Version 1 feature is removed by this ordering.

## Version 1 learning loop

1. Open quizMoi and see saved material, current work, and real progress.
2. Paste text, select a PDF, photograph study material, or enter a supported article URL.
3. Preview and confirm pasted/URL text, PDF metadata, or the captured image before the material leaves the device.
4. Choose difficulty, question types, and count.
5. Generate validated questions through a quizMoi-controlled backend.
6. Edit, remove, reorder, or regenerate questions before saving.
7. Complete a persistent quiz session with clear navigation safeguards.
8. See deterministic scoring, grounded explanations, and concepts to review.
9. Return later to saved history and a personalized review queue.

## Phase 3 prototype behavior

- Pasted French or bilingual text only, between 200 and 12,000 characters.
- Ten medium-difficulty multiple-choice questions by default.
- Required preview and confirmation before generation.
- Four unique options and exactly one valid correct answer per question.
- Explanation, source excerpt, and concept tags required for every generated question.
- Generated quiz must be reviewed before local save.
- Source, quiz, session, attempt, and feedback survive restart.
- **Try Demo Quiz** remains a clearly separate offline sample.
- Entered text remains available after recoverable failures and can be retried.

## Complete Version 1 capabilities

### Content

- Pasted French or bilingual text
- PDFs sent through the quizMoi backend as OpenAI file input after explicit confirmation
- Camera-captured pages sent through the quizMoi backend as OpenAI image input after preview and explicit confirmation
- Supported public web articles
- Backend-cleaned article preview before AI generation, with the final public URL retained beside local source text
- Preview, validation, source references, and deletion
- Clear empty, unsupported, oversized, protected, scanned, and unreachable states

### Quiz creation

- Multiple-choice and typed-answer questions
- Difficulty, type, and question-count controls
- Generated-question review, editing, ordering, removal, and regeneration
- Manual quiz creation when AI is unavailable

### Quiz sessions

- Answer selection and typed input
- Previous/next, skip/review, timer, pause/resume, restart, exit, and final confirmation
- Persistent restoration after process death or restart

### Results and review

- Correct, incorrect, and unanswered counts
- Question-level explanation and source evidence
- Weak concepts and actionable recommendations
- Attempt history, saved results, mastery, and daily review queue

### Learner data

- Local-first profile, preferences, sources, quizzes, attempts, and sessions
- Accounts and synchronization only when private testing demonstrates a real need

## Design and accessibility

- Android-first layouts support narrow phones and enlarged text.
- Interactive targets are at least 48 logical pixels where practical.
- Important meaning is not communicated by color alone.
- Controls expose labels and selected state to accessibility services.
- French accents and common input methods work correctly.
- Loading, empty, error, retry, offline, and unavailable states use clear language.
- Android camera permission is requested only when the learner chooses the camera action, with a usable denial/retry path.
- Dark mode remains deferred until after the complete learning loop.

## Privacy and AI

- LLM credentials never enter the Android application or repository.
- AI calls pass through a quizMoi-controlled backend.
- Confirmed PDFs are uploaded to the local backend and included directly in a Responses API request; Flutter never receives the OpenAI credential.
- Confirmed camera images follow the same backend-only credential boundary and are not uploaded before the learner previews and accepts the photograph.
- Web URLs are retrieved only by the backend; local/private destinations, unsupported content, and common protected/paywalled pages are rejected before AI generation.
- Imported material and learner answers are private by default and excluded from logs.
- Generated output is schema-validated and grounded before presentation.
- Learners can delete imported sources and generated study data.

## Deferred beyond Version 1

- YouTube transcription
- Flashcards and generated notes
- Social features and leaderboards
- Subscriptions and payments
- Production iOS, web, and desktop support
- Public Google Play Store release

## Completion criteria

- The complete source-to-review loop works on supported Android devices.
- Data survives restarts and upgrades.
- Analyzer, automated tests, and Android builds pass in CI.
- No critical/high privacy, security, data-loss, scoring, or accessibility defects remain.
- Private testers understand the app without developer assistance.
- Quiz quality, latency, and operating cost meet documented targets before public-release work.
