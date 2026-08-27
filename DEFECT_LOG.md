# quizMoi Defect and Improvement Log

This log records issues found during emulator and self-use testing. Entries stay open until the behavior is reproduced, fixed, covered by a test, and manually verified.

## Status and priority

- **Open:** recorded but not fixed.
- **Investigating:** cause is still being confirmed.
- **Ready to verify:** a fix exists and needs emulator testing.
- **Closed:** fixed and verified.
- **High:** misleading results, data loss, crashes, or broken core navigation.
- **Medium:** important workflow problem that has a workaround.
- **Low:** cosmetic or uncommon edge case.

## QM-001 — Offline demo is absent from Recent Attempts

- **Status:** Open
- **Priority:** Medium
- **Found:** 2026-08-17, Android 17 emulator
- **Target:** Phase 5 self-use alpha, before relying on dashboard metrics
- **Observed:** Completing the ten-question offline demo shows results and appeared to change dashboard accuracy, but the demo is not listed under **Recent Attempts**.
- **Expected:** The product must use one clear rule: either persist the demo and include it consistently in history and metrics, or label it as practice and exclude it consistently from all dashboard metrics.
- **Reproduction:** Open **Add Content**, select **Try Offline Demo Quiz**, complete and submit all ten questions, return to the dashboard, and compare accuracy with **Recent Attempts**.
- **Initial cause:** `QuizProvider.startQuiz()` creates a transient UI quiz. It does not create a saved `QuizDefinition`, so `persistSession()` exits without saving an attempt. `AttemptHistoryProvider` can only display attempts linked to quizzes in `QuizRepository`.
- **Investigation note:** Dashboard accuracy is calculated from persisted history, not directly from the transient demo score. The reported accuracy change should be reproduced while recording the before/after value to determine whether history loaded asynchronously or another stored attempt changed it.
- **Acceptance:** Demo behavior and labels are consistent; its completion either appears everywhere or affects no persistent metric; automated coverage verifies the chosen rule.

## QM-002 — Daily goal shows 24/10 after one visible quiz

- **Status:** Investigating
- **Priority:** High
- **Found:** 2026-08-17, Android 17 emulator
- **Target:** Phase 5 self-use alpha, before relying on dashboard metrics
- **Observed:** After completing one ten-question demo, the dashboard displayed **24 / 10 Questions** and indicated that the daily goal was complete.
- **Expected:** The counter must clearly represent today's persisted learning activity and agree with Recent Attempts. With no other qualifying activity, one ten-question quiz should show **10 / 10 Questions**.
- **Reproduction:** Record the counter and Recent Attempts, complete one quiz, return to the dashboard, refresh history, and compare the counter change with the completed attempt's question count.
- **Initial cause:** `questionsCompletedToday` sums the full question count of every persisted completed attempt whose completion timestamp matches the emulator's local day. App rebuilds preserve SQLite data, and retaking a quiz counts its questions again. The offline demo itself is not persisted and therefore cannot directly add ten questions.
- **Evidence:** The emulator clock and the existing `quiz_moi.sqlite` database are both dated 2026-08-17. The database was deliberately preserved for later inspection.
- **Questions to resolve:** Identify the attempts contributing 24 questions; decide whether retries count toward the daily goal; make the dashboard total and visible history use the same eligibility rules; decide whether progress text should cap at the goal or show overachievement separately.
- **Acceptance:** The displayed total can be reconciled to visible qualifying attempts, the product rule for retries is documented, and automated tests cover multiple quizzes, retries, deleted quizzes, day boundaries, and values above the goal.

## QM-003 — Generated-quiz review reveals answers before testing

- **Status:** Open
- **Priority:** High
- **Found:** 2026-08-17, real Phase 3 OpenAI integration test
- **Target:** Phase 3 UX follow-up or Phase 5 self-use alpha, before regular learning use
- **Observed:** After generation, the learner sees all ten questions, four options, the marked correct answer, explanation, and supporting source excerpt before saving and starting the quiz. This reveals the answers and weakens the active-recall test. Requiring a separate save step also adds friction to the main learning journey.
- **Expected:** The default learner journey should not expose correct answers or explanations before the attempt. A learner should be able to paste or import material, generate a validated quiz, and begin testing with minimal intermediate work.
- **Recommended default flow:** Preview source → generate → validate on the backend and client → transactionally save source and quiz → start the quiz immediately. Show correct answers, explanations, and source evidence only after submission.
- **Editing alternative:** Preserve **Review/Edit Quiz** as an optional advanced action from the generated confirmation, saved-quiz menu, or post-attempt results. If pre-attempt review remains available, clearly warn that it reveals answers and treat it as authoring mode rather than the normal learner flow.
- **Tradeoff:** Removing mandatory review reduces answer leakage and friction, but it also removes the learner’s manual quality gate for ambiguous or factually weak AI questions. Structural and grounding validation already blocks malformed output, but it cannot guarantee that every question is pedagogically strong. The final design should combine immediate play with an easy **Report/Edit Question** action.
- **Decisions needed:** Choose the default knowledge-base assignment, generated title behavior, save-failure recovery, whether to offer **Start Now** versus **Review First**, and where post-generation editing lives.
- **Acceptance:** The normal generation path starts a persisted quiz without revealing answers; saving remains reliable and retryable; optional editing is still discoverable; explanations appear after submission; widget tests and an emulator check cover both the default and optional paths.

## QM-004 — Successful AI response can be lost after a connection interruption

- **Status:** Resolved 2026-08-27
- **Priority:** High
- **Found:** 2026-08-17, real Phase 4 PDF/OpenAI emulator test
- **Target:** Phase 4 follow-up, before routine PDF self-use
- **Observed:** FastAPI completed `POST /v1/quizzes/generate-pdf` with `200 OK`, but Flutter displayed **The local quiz server is not reachable** and discarded the successful generated quiz. Pressing **Retry** made another provider request and then completed generation.
- **Evidence:** Emulator logs show the virtual default network switching while the request was active. A subsequent emulator-to-host check returned three successful packets with zero loss. The current Flutter gateway maps every `http.ClientException` to `backend_unavailable`, even when the server completed the request.
- **Expected:** A temporary interruption after server acceptance must not silently lose a completed result or require a second paid generation. The message must distinguish initial connection failure from a response interrupted after submission.
- **Implemented:** Flutter now creates one stable generation request ID and reuses it for retries. FastAPI temporarily retains the in-progress task or completed quiz, verifies that the ID still represents identical input, and returns the retained result without calling the provider again. Flutter distinguishes an interrupted response from an unreachable backend and presents **Recover Result** while preserving the selected source.
- **Prototype limit:** Recovery data is held in backend memory for one hour (up to 64 entries). Restarting FastAPI clears it; durable recovery and background jobs remain Phase 7 work.
- **Automated evidence:** Backend tests cover text/PDF result reuse, conflicting input, and recovery after a cancelled first waiter. Flutter tests cover request-ID reuse, interrupted-response classification, and recovery language. All focused tests pass.
- **Manual evidence:** A real emulator PDF generation was accepted, then Android airplane mode interrupted the response. The app preserved the selected PDF and request identity; after connectivity returned, retry opened the generated quiz from the retained operation. Because the full network was offline, the immediate health probe correctly produced **Retry**; the narrower reachable-backend wording is covered by the focused widget test.
- **Acceptance:** Repeating the same generation request after a simulated response interruption returns the original result without another provider call; the learner sees accurate recovery language; focused backend and Flutter tests cover the scenario; emulator verification passes.

## QM-005 — Generated correct answers are all in option A

- **Status:** Ready to verify
- **Priority:** High
- **Found:** 2026-08-27, real Phase 4 web-article/OpenAI emulator test
- **Target:** Phase 4 quiz-quality follow-up, before routine self-use
- **Observed:** The ten-question quiz generated from the French Wikipedia article **Pain** placed the correct answer in option A for every question. Selecting the first option ten times produced a 100% score.
- **Evidence:** The completed emulator attempt shows 10 of 10 correct, and the persisted quiz records option position 0 as the correct option for all ten questions.
- **Expected:** Correct-answer positions should be distributed unpredictably so a learner cannot score well by repeatedly choosing the same position. Reordering must preserve each option's stable ID and the correct-answer mapping.
- **Likely area:** The structured generation contract labels the correct answer and options, but the generation prompt and client save path do not currently require or perform answer-position randomization.
- **Implemented:** FastAPI deterministically shuffles each generated MCQ's option order using the request ID and question index. Stable option IDs and `correctOptionId` remain unchanged.
- **Remaining verification:** Generate a real ten-question MCQ set on Android and confirm correct answers are not concentrated in one visible position.
- **Acceptance:** Generated MCQ sets randomize option order safely, preserve answer/explanation correctness, avoid obvious position bias across a reviewed evaluation set, and pass unit plus emulator tests.
