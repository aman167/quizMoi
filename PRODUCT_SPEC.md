# quizMoi Version 1 Product Specification

Status: Draft for private development  
Last updated: 2026-08-17

## Product promise

quizMoi helps a French learner turn their own study material into active-recall practice, understand mistakes, and return to weak concepts at the right time.

Version 1 is successful when one learner can import material, review an automatically generated quiz, complete it, understand the results, and later resume a personalized review routine without losing work.

## Primary learner

The first version is designed for an independent beginner-to-intermediate French learner who already has material to study but does not want to create every practice question manually.

The interface should assume the learner may be new to both French study systems and quiz-generation tools. Actions, limitations, loading states, and errors must be explained in plain language.

## Version 1 learning loop

1. The learner opens quizMoi and sees saved material, current review work, and progress based on real attempts.
2. The learner pastes text, selects a PDF, or enters a supported article URL.
3. quizMoi extracts and previews the source so the learner can confirm what will be used.
4. The learner chooses difficulty, question types, and question count.
5. The backend generates structured questions grounded in the confirmed source.
6. The learner reviews, edits, removes, or regenerates weak questions before saving the quiz.
7. During testing, the app saves progress, prevents accidental data loss, and gives clear navigation feedback.
8. After submission, the learner sees deterministic scoring, source-grounded explanations, and concepts to review.
9. The completed attempt updates history, statistics, mastery, and the next review queue.

## Version 1 capabilities

### Content

- Pasted French or bilingual text
- Text-based PDF documents
- Supported public web articles
- Source preview and validation
- Clear handling for empty, unsupported, oversized, protected, or unreachable content

### Quiz creation

- Multiple-choice questions
- Typed-answer and fill-in-the-blank questions
- Difficulty and question-count controls
- Generated-question review and editing
- Manual quiz creation as an AI-independent fallback

### Quiz sessions

- Answer selection and typed input
- Previous/next navigation
- Required-answer and skipped-answer rules that are explicit to the learner
- Timer, restart, exit confirmation, and session restoration
- Final submission confirmation

### Results and review

- Correct, incorrect, and unanswered counts
- Question-level explanations linked to source evidence
- Weak-concept recommendations
- Attempt history and saved results
- Daily review queue and documented mastery rules

### Learner data

- Local-first profile and settings
- Saved sources, quizzes, attempts, and in-progress sessions
- Account and synchronization only when private testing demonstrates a real need

## Current demo-mode contract

The local learning core is persistent, but content ingestion and AI generation remain prototypes:

- knowledge bases, learner settings, manual quizzes, attempts, and Dashboard statistics are real local data;
- questions and explanations reached through **Try Demo Quiz** are explicitly sample content;
- the content field does not generate source-specific questions;
- the primary action is labelled **Try Demo Quiz**;
- unavailable controls must explain that they are planned instead of failing silently;
- the Stats screen must show an empty state when no quiz exists instead of inventing results;
- saved manual-quiz sessions must remain resumable, while restart and abandonment require confirmation.

## Deferred beyond version 1

- YouTube transcription
- Camera and image ingestion
- Flashcards and generated notes
- Social features and leaderboards
- Subscriptions and payments
- Production support for iOS, web, and desktop
- Public Google Play Store release

These items may be reconsidered after the Android learning loop is reliable and private testers demonstrate demand.

## Design and accessibility requirements

- Android-first layouts must work at narrow phone widths and with enlarged text.
- Interactive targets should be at least 48 logical pixels where practical.
- Icons require labels or tooltips when their purpose is not obvious.
- Selected answers and navigation tabs must expose selected state to accessibility services.
- Important meaning cannot rely on color alone.
- Loading, empty, error, retry, offline, and unavailable states must use clear language.
- French accents and common input methods must display and behave correctly.

Dark mode is deferred until after the complete version 1 learning loop. The current Crimson Velocity light theme remains the supported theme during private development.

## Privacy and AI rules

- LLM credentials must never be stored in the Android application.
- AI requests must pass through a quizMoi-controlled backend.
- Imported study material is private by default and must not appear in logs.
- Generated answers must be validated before presentation.
- Explanations should cite the source segment used when possible.
- Learners must be able to delete imported sources and generated study data.

## Version 1 completion criteria

- The complete source-to-review loop works on supported Android devices.
- Data survives app restarts and upgrades.
- Analyzer, automated tests, and Android builds pass in continuous integration.
- No critical or high-severity privacy, security, data-loss, or accessibility defects remain.
- Private testers can understand the app without developer assistance.
- Quiz quality, latency, and operating cost meet documented targets before public-release work begins.
