import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_attempt_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/attempt_history_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/widgets/attempt_history_section.dart';

void main() {
  test('calculates real accuracy from completed attempts only', () async {
    final now = DateTime(2026, 8, 17, 15);
    final quizzes = MemoryQuizRepository(
      initialQuizzes: [_quiz('quiz-1', 'Travel French', now, 2)],
    );
    final attempts = MemoryAttemptRepository(
      initialAttempts: [
        _attempt(
          id: 'completed',
          status: AttemptStatus.completed,
          completedAt: now,
          answers: const {'question-1': 'a', 'question-2': 'b'},
        ),
        _attempt(
          id: 'in-progress',
          status: AttemptStatus.inProgress,
          answers: const {'question-1': 'a'},
        ),
      ],
    );
    final provider = AttemptHistoryProvider(
      attemptRepository: attempts,
      quizRepository: quizzes,
      now: () => now,
    );

    await provider.load();

    expect(provider.state, AttemptHistoryLoadState.ready);
    expect(provider.completedAttemptCount, 1);
    expect(provider.totalCorrectAnswers, 1);
    expect(provider.totalQuestions, 2);
    expect(provider.accuracyPercent, 50);
    expect(provider.questionsCompletedToday, 2);
  });

  test('skips attempts whose quiz has been deleted', () async {
    final now = DateTime(2026, 8, 17, 15);
    final provider = AttemptHistoryProvider(
      attemptRepository: MemoryAttemptRepository(
        initialAttempts: [
          _attempt(
            id: 'orphaned',
            status: AttemptStatus.completed,
            completedAt: now,
            answers: const {'question-1': 'a'},
          ),
        ],
      ),
      quizRepository: MemoryQuizRepository(),
      now: () => now,
    );

    await provider.load();

    expect(provider.entries, isEmpty);
    expect(provider.accuracyPercent, 0);
  });

  testWidgets('shows a completed attempt and its score', (tester) async {
    final now = DateTime(2026, 8, 17, 15);
    final provider = AttemptHistoryProvider(
      attemptRepository: MemoryAttemptRepository(
        initialAttempts: [
          _attempt(
            id: 'completed',
            status: AttemptStatus.completed,
            completedAt: now,
            answers: const {'question-1': 'a', 'question-2': 'b'},
          ),
        ],
      ),
      quizRepository: MemoryQuizRepository(
        initialQuizzes: [_quiz('quiz-1', 'Travel French', now, 2)],
      ),
      now: () => now,
    );
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AttemptHistorySection()),
          ),
        ),
      ),
    );

    expect(find.text('Recent Attempts'), findsOneWidget);
    expect(find.text('Travel French'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('1 of 2 correct'), findsOneWidget);
  });
}

QuizAttempt _attempt({
  required String id,
  required AttemptStatus status,
  required Map<String, String> answers,
  DateTime? completedAt,
}) {
  final startedAt = DateTime(2026, 8, 17, 14);
  return QuizAttempt(
    id: id,
    quizId: 'quiz-1',
    status: status,
    answers: answers.entries
        .map(
          (entry) => QuestionAnswer(
            questionId: entry.key,
            value: entry.value,
            answeredAt: startedAt,
          ),
        )
        .toList(),
    currentQuestionIndex: 0,
    elapsedSeconds: 75,
    startedAt: startedAt,
    completedAt: completedAt,
  );
}

QuizDefinition _quiz(
  String id,
  String title,
  DateTime timestamp,
  int questionCount,
) => QuizDefinition(
  id: id,
  title: title,
  createdAt: timestamp,
  updatedAt: timestamp,
  questions: List.generate(
    questionCount,
    (index) => QuestionDefinition(
      id: 'question-${index + 1}',
      prompt: 'Question ${index + 1}',
      type: QuestionType.multipleChoice,
      options: const [
        AnswerOption(id: 'a', text: 'Correct'),
        AnswerOption(id: 'b', text: 'Incorrect'),
      ],
      correctAnswer: 'a',
    ),
  ),
);
