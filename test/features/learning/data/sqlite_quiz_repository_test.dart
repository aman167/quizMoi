import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late QuizDatabase database;
  late SqliteQuizRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = SqliteQuizRepository(database);
  });

  tearDown(() => database.close());

  test('saves and restores a complete quiz aggregate', () async {
    final quiz = _sampleQuiz();

    await repository.save(quiz);
    final restored = await repository.getById(quiz.id);

    expect(restored, isNotNull);
    expect(restored!.toJson(), quiz.toJson());
  });

  test('updates a quiz atomically and removes replaced questions', () async {
    final quiz = _sampleQuiz();
    await repository.save(quiz);
    final replacement = quiz.copyWith(
      title: 'Updated French Basics',
      questions: [quiz.questions.last],
      updatedAt: quiz.updatedAt.add(const Duration(minutes: 5)),
    );

    await repository.save(replacement);
    final restored = await repository.getById(quiz.id);

    expect(restored!.title, 'Updated French Basics');
    expect(restored.questions, hasLength(1));
    expect(restored.questions.single.id, 'question-2');
  });

  test('hides archived quizzes by default and deletes with children', () async {
    final quiz = _sampleQuiz();
    await repository.save(quiz.copyWith(isArchived: true));

    expect(await repository.getAll(), isEmpty);
    expect(await repository.getAll(includeArchived: true), hasLength(1));

    await repository.delete(quiz.id);

    expect(await repository.getById(quiz.id), isNull);
    final countRows = await database.connection.rawQuery(
      'SELECT COUNT(*) AS count FROM questions',
    );
    final questionCount = countRows.single['count']! as int;
    expect(questionCount, 0);
  });
}

QuizDefinition _sampleQuiz() {
  final createdAt = DateTime.utc(2026, 8, 17, 9);
  const concept = Concept(
    id: 'daily-vocabulary',
    name: 'Daily vocabulary',
    category: 'Vocabulary',
  );
  return QuizDefinition(
    id: 'quiz-1',
    title: 'French Basics',
    createdAt: createdAt,
    updatedAt: createdAt,
    questions: [
      QuestionDefinition(
        id: 'question-1',
        prompt: 'Que signifie « quotidien » ?',
        type: QuestionType.multipleChoice,
        options: const [
          AnswerOption(id: 'a', text: 'Rare'),
          AnswerOption(id: 'b', text: 'Journalier'),
        ],
        correctAnswer: 'b',
        explanation: const QuestionExplanation(
          text: 'Quotidien signifie chaque jour.',
          sourceExcerpt: 'la vie quotidienne',
        ),
        concepts: const [concept],
      ),
      QuestionDefinition(
        id: 'question-2',
        prompt: 'Traduisez « chaque jour ».',
        type: QuestionType.typedAnswer,
        options: const [],
        correctAnswer: 'every day',
        concepts: const [concept],
      ),
    ],
  );
}
