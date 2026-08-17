import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_attempt_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/state/quiz_provider.dart';

void main() {
  test('restores the latest in-progress saved quiz', () async {
    final now = DateTime.utc(2026, 8, 17, 14);
    final quiz = _quiz(now);
    final quizRepository = MemoryQuizRepository(initialQuizzes: [quiz]);
    final attemptRepository = MemoryAttemptRepository(
      initialAttempts: [
        QuizAttempt(
          id: 'attempt-1',
          quizId: quiz.id,
          status: AttemptStatus.inProgress,
          answers: [
            QuestionAnswer(
              questionId: 'question-1',
              value: 'a',
              answeredAt: now.add(const Duration(seconds: 8)),
            ),
          ],
          currentQuestionIndex: 1,
          elapsedSeconds: 18,
          startedAt: now,
        ),
      ],
    );
    final provider = QuizProvider(attemptRepository: attemptRepository);

    expect(await provider.restoreInProgress(quizRepository), isTrue);

    expect(provider.hasResumableSession, isTrue);
    expect(provider.currentQuiz!.title, 'Travel French');
    expect(provider.currentQuiz!.questions.first.selectedOptionId, 'a');
    expect(provider.currentQuestionIndex, 1);
    expect(provider.elapsedSeconds, 18);
  });

  test('persists progress, completion, and a saved-quiz retake', () async {
    final now = DateTime.utc(2026, 8, 17, 14);
    final attempts = MemoryAttemptRepository();
    var historyRefreshes = 0;
    final provider = QuizProvider(
      attemptRepository: attempts,
      now: () => now,
      onAttemptCompleted: () async {
        historyRefreshes++;
      },
    );
    final quiz = _quiz(now);

    provider.startSavedQuiz(quiz);
    provider.selectOption('a');
    provider.nextQuestion();
    provider.selectOption('b');
    expect(provider.nextQuestion(), isTrue);
    await provider.persistSession();

    expect(provider.quizCompleted, isTrue);
    expect(await attempts.getLatestInProgress(), isNull);
    final completed = await attempts.getForQuiz(quiz.id);
    expect(completed.single.status, AttemptStatus.completed);
    expect(completed.single.answers, hasLength(2));
    expect(historyRefreshes, 1);

    provider.retakeCurrentQuiz();
    await provider.persistSession();
    expect(provider.currentQuiz!.title, 'Travel French');
    expect(provider.quizCompleted, isFalse);
    expect(await attempts.getLatestInProgress(), isNotNull);
    expect(await attempts.getForQuiz(quiz.id), hasLength(2));
  });

  test('abandon removes the resumable attempt', () async {
    final now = DateTime.utc(2026, 8, 17, 14);
    final attempts = MemoryAttemptRepository();
    final provider = QuizProvider(attemptRepository: attempts, now: () => now)
      ..startSavedQuiz(_quiz(now));
    await provider.persistSession();

    await provider.abandonQuiz();

    expect(provider.currentQuiz, isNull);
    expect(await attempts.getLatestInProgress(), isNull);
  });

  test('restart keeps the saved quiz but clears its progress', () async {
    final now = DateTime.utc(2026, 8, 17, 14);
    final attempts = MemoryAttemptRepository();
    final provider = QuizProvider(attemptRepository: attempts, now: () => now)
      ..startSavedQuiz(_quiz(now));
    provider.selectOption('a');
    provider.incrementTimer();
    await provider.persistSession();

    await provider.restartCurrentQuiz();
    await provider.persistSession();

    expect(provider.currentQuiz!.title, 'Travel French');
    expect(provider.currentQuestionIndex, 0);
    expect(provider.currentQuiz!.answeredCount, 0);
    expect(provider.elapsedSeconds, 0);
    expect(await attempts.getForQuiz('quiz-1'), hasLength(1));
  });
}

QuizDefinition _quiz(DateTime timestamp) => QuizDefinition(
  id: 'quiz-1',
  title: 'Travel French',
  createdAt: timestamp,
  updatedAt: timestamp,
  questions: [
    QuestionDefinition(
      id: 'question-1',
      prompt: 'Que signifie bonjour ?',
      type: QuestionType.multipleChoice,
      options: const [
        AnswerOption(id: 'a', text: 'Hello'),
        AnswerOption(id: 'b', text: 'Goodbye'),
      ],
      correctAnswer: 'a',
    ),
    QuestionDefinition(
      id: 'question-2',
      prompt: 'Que signifie au revoir ?',
      type: QuestionType.multipleChoice,
      options: const [
        AnswerOption(id: 'a', text: 'Please'),
        AnswerOption(id: 'b', text: 'Goodbye'),
      ],
      correctAnswer: 'b',
    ),
  ],
);
