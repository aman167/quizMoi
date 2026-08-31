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

- [ ] Pasted text: preview, generate, auto-save, complete, results, restart.
- [ ] PDF: select, preview, generate, complete, restart.
- [ ] Public URL: retrieve, preview cleaned text, generate, complete, restart.
- [ ] Camera: permission on demand, capture/retake, preview, generate, complete.
- [ ] Offline demo: complete and reconcile history/dashboard totals.

### Quiz breadth

- [ ] Multiple-choice scoring and explanations.
- [ ] Typed-answer normalization, accepted alternatives, and accents.
- [ ] Five-, ten-, and fifteen-question generation.
- [ ] Easy, medium, and hard difficulty settings.
- [ ] Optional time limit and timeout submission.
- [ ] Previous, skip, review, pause/resume, restart, exit, and retake.

### Local learning data

- [ ] Saved quiz edit, duplicate, archive, restore, and delete.
- [ ] Knowledge-base create, assignment, archive, and safe deletion.
- [ ] Source duplicate detection and deletion without losing quizzes.
- [ ] Dashboard accuracy, daily goal, streak, history, and recommendations.
- [ ] Force-stop/reopen restores saved data and an in-progress attempt.

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
