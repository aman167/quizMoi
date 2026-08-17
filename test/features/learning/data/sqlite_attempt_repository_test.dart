import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_attempt_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late QuizDatabase database;
  late SqliteAttemptRepository repository;
  late DateTime startedAt;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = SqliteAttemptRepository(database);
    startedAt = DateTime.utc(2026, 8, 17, 13);
    await SqliteQuizRepository(database).save(_quiz(startedAt));
  });

  tearDown(() => database.close());

  test('round-trips an in-progress attempt and its answers', () async {
    final attempt = _attempt(startedAt);

    await repository.save(attempt);
    final restored = await repository.getLatestInProgress();

    expect(restored, isNotNull);
    expect(restored!.toJson(), attempt.toJson());
  });

  test('updates progress and no longer resumes a completed attempt', () async {
    final attempt = _attempt(startedAt);
    await repository.save(attempt);
    final completed = attempt.copyWith(
      status: AttemptStatus.completed,
      currentQuestionIndex: 0,
      elapsedSeconds: 42,
      completedAt: startedAt.add(const Duration(seconds: 42)),
    );

    await repository.save(completed);

    expect(await repository.getLatestInProgress(), isNull);
    final history = await repository.getForQuiz('quiz-1');
    expect(history.single.toJson(), completed.toJson());
  });

  test('deleting an attempt also deletes its stored answers', () async {
    final attempt = _attempt(startedAt);
    await repository.save(attempt);

    await repository.delete(attempt.id);

    expect(await repository.getForQuiz('quiz-1'), isEmpty);
    final rows = await database.connection.rawQuery(
      'SELECT COUNT(*) AS count FROM question_answers',
    );
    expect(rows.single['count'], 0);
  });
}

QuizAttempt _attempt(DateTime startedAt) => QuizAttempt(
  id: 'attempt-1',
  quizId: 'quiz-1',
  status: AttemptStatus.inProgress,
  answers: [
    QuestionAnswer(
      questionId: 'question-1',
      value: 'a',
      answeredAt: startedAt.add(const Duration(seconds: 8)),
    ),
  ],
  currentQuestionIndex: 0,
  elapsedSeconds: 8,
  startedAt: startedAt,
);

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
  ],
);
