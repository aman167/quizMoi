# quizMoi Phase 5 Self-Use Alpha Plan

Started: 2026-08-31

## Purpose

Phase 5 tests whether the complete private Android application is useful and trustworthy during real French study. It prioritizes crashes, data loss, broken navigation, incorrect scoring, misleading feedback, and unusable AI output over cosmetic polish or new feature ideas.

## Baseline

- Branch: `main`
- Flutter tests: 82 passing
- Backend tests: 19 passing
- Static analysis: no issues
- Android debug APK: builds successfully
- Logged pre-alpha defects: QM-001 through QM-005 closed
- API-key boundary: backend environment only; no key in Flutter or Git

## Checkpoint 5.1 — Alpha foundation

- [x] Define the smoke-test matrix and severity rules.
- [x] Record the automated baseline.
- [x] Keep findings in `DEFECT_LOG.md` using the template below.
- [x] Save the checkpoint to GitHub.

## Checkpoint 5.2 — Clean-emulator smoke test

Use a clean Android installation and preserve its data between test cases.

### Core generation journeys

- [x] Pasted text: preview, generate, auto-save, complete, results, restart.
- [x] PDF: select, preview, generate, complete, restart.
- [x] Public URL: retrieve, preview cleaned text, generate, complete, restart.
- [x] Camera: permission on demand, capture/retake, preview, generate, complete.
- [x] Offline demo: complete and reconcile history/dashboard totals.

### Quiz breadth

- [x] Multiple-choice scoring and explanations.
- [x] Typed-answer input, timeout scoring, and accent-sensitive behavior.
- [x] Typed-answer case/whitespace/punctuation normalization and accepted alternatives.
- [x] Five- and ten-question generation.
- [x] Fifteen-question generation.
- [x] Easy and medium difficulty settings.
- [x] Hard difficulty setting.
- [x] Optional time limit and timeout submission.
- [x] Previous, skip, answer review, pause, resume, and question-status restoration.
- [x] Confirmed restart, discard, and completed-quiz retake.

### Local learning data

- [x] Saved quiz edit, duplicate, archive, restore, and delete.
- [x] Knowledge-base create, assignment, archive, and safe deletion.
- [x] Source duplicate detection reuses one source across generated quizzes.
- [x] Source deletion preserves linked quizzes and attempts.
- [x] Dashboard accuracy, daily goal, streak, history, and recommendations.
- [x] Force-stop/reopen and APK upgrade restore saved, completed, and in-progress data.

### Failure behavior

- [ ] Empty, short, unsupported, oversized, and non-French input.
- [ ] Backend unavailable before generation.
- [ ] Interrupted response and result recovery.
- [ ] Save failure preserves the generated draft for retry.
- [ ] Camera and notification permission denial/retry.

## Checkpoint 5.3 — Physical Android phone

- [ ] Enable developer options and USB debugging.
- [ ] Install the private debug APK over USB.
- [ ] Configure a development API address reachable on private Wi-Fi.
- [ ] Verify text, PDF, camera, keyboard, notification, and restart behavior.
- [ ] Confirm the phone contains no OpenAI credential.

## Checkpoint 5.4 — Real self-use trial

- [ ] Use quizMoi on at least five active days.
- [ ] Complete at least one genuine study quiz per active day.
- [ ] Use at least three source types and both question types.
- [ ] Retake at least one weak-concept recommendation.
- [ ] Log confusing UX, poor AI output, defects, and improvement ideas.

## Phase 5 exit criteria

- [ ] No known critical or high defects remain.
- [ ] No observed data loss, incorrect scoring, or broken core journey remains.
- [ ] Major journeys work on the emulator and the owner's Android phone.
- [ ] Persistence survives ordinary restarts and upgrades.
- [ ] AI output is useful enough for regular French study.
- [ ] Remaining medium/low findings have an explicit decision.
- [ ] Tests, analyzer, secret scan, and debug APK build remain green.

## Test-session notes

For each session, record the date, device, app commit, sources tested, result, and related defect IDs. Never paste private source content or API keys into this file.

- 2026-08-31 — Android 17 emulator, commit `39ad237`: real pasted-text/OpenAI quiz **La routine de Marie** generated ten MCQs, auto-saved without answer leakage, completed with matching score, showed explanations only after submission, and survived force-stop/reopen. Dashboard restored 40.7% aggregate accuracy, 10/10 questions today, a one-day streak, recommendations, and the named 0/10 attempt in Recent Attempts. No new defect reported.
- 2026-08-31 — Android 17 emulator, commit `39ad237`: repeated the Marie source with five easy typed-answer questions and a five-minute limit. Timeout submitted at exactly 5:00 with two correct and three wrong/skipped; feedback remained grounded and correctly treated `pres` as different from `près`. SQLite inspection confirmed **La routine de Marie** and **La vie de Marie** share one source-document ID. No new defect reported.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: generated 15 hard alternating MCQ/typed questions from the French PDF and verified skip, answer-status review, and jump-back navigation. Testing found QM-006: pause/restart controls were clipped. The responsive fix was installed as an APK upgrade without clearing data; the attempt restored at Question 3 with 1/15 answered, displayed **Pause & Exit**, and returned safely to a resumable dashboard card.
- 2026-08-31 — Android 17 emulator, commit `b1f38dd`: completed the 15-question PDF journey after verifying restart/discard confirmation cancellation. Jumped to Question 15, submitted with unanswered questions, received skipped-question feedback, retook with Question 1/zero answers/reset timer, and intentionally discarded the retake. All controls and persistence behaved as specified.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: retrieved and previewed cleaned text from the public French Wikipedia **Pain** article, generated and auto-saved five medium MCQs, submitted five unanswered questions, received 0/5 with grounded explanations/source evidence, and confirmed the saved quiz on the dashboard. No new defect reported.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: opened the camera without a repeated permission prompt because access was already granted, loaded a French test page into the emulator virtual scene, captured and previewed it, generated and completed the AI quiz, verified results and source-grounded feedback, confirmed Saved Quizzes and Recent Attempts, and confirmed persistence after restarting the app. No new defect reported.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: launched the offline demo without an AI request, used Review Answers to jump to the final question, submitted with unanswered questions, verified the result total and feedback, and confirmed that Recent Attempts and the daily-question counter updated by the correct quiz size. No new defect reported.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: created a four-question manual typed-answer quiz and earned 4/4 using uppercase input, surrounding whitespace, trailing punctuation, and an explicitly accepted alternative. Deterministic typed-answer normalization passed with no new defect.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: edited and saved the temporary Scoring Test quiz, duplicated it, archived and restored the original, deleted both copies through their confirmation dialogs, restarted the app, and confirmed neither deleted quiz returned. No new defect reported.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: created a knowledge base, assigned a saved quiz, archived and restored the folder, deleted it through the safety confirmation, and confirmed the assigned quiz remained available. No new defect reported.
- 2026-08-31 — Android 17 emulator, Phase 5 branch: deleted the stored source for a generated quiz, confirmed the saved quiz and previous attempt remained available, retook the quiz successfully, and verified its scoring and feedback still worked. No new defect reported.
