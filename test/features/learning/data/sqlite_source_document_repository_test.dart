import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_source_document_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late QuizDatabase database;
  late SqliteSourceDocumentRepository sources;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    sources = SqliteSourceDocumentRepository(database);
  });

  tearDown(() => database.close());

  test('source round trip and quiz link survive persistence', () async {
    final now = DateTime.utc(2026, 8, 17, 18);
    final source = SourceDocument(
      id: 'source-1',
      title: 'French article',
      type: SourceType.pastedText,
      content: List.filled(20, 'Bonjour tout le monde.').join(' '),
      sourceUri: 'https://example.com/fr/article',
      createdAt: now,
    );
    await sources.save(source);
    await SqliteQuizRepository(database).save(
      QuizDefinition(
        id: 'quiz-1',
        sourceDocumentId: source.id,
        title: 'Generated quiz',
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
            explanation: const QuestionExplanation(
              text: 'Bonjour means hello.',
              sourceExcerpt: 'Bonjour tout le monde.',
            ),
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );

    final restoredSource = await sources.getById(source.id);
    expect(restoredSource!.content, source.content);
    expect(restoredSource.sourceUri, 'https://example.com/fr/article');
    expect(
      (await SqliteQuizRepository(
        database,
      ).getById('quiz-1'))!.sourceDocumentId,
      source.id,
    );
  });

  test('deleting a source preserves its quiz and clears the link', () async {
    final now = DateTime.utc(2026, 8, 17, 18);
    await sources.save(
      SourceDocument(
        id: 'source-1',
        title: 'French article',
        type: SourceType.pastedText,
        content: List.filled(20, 'Bonjour tout le monde.').join(' '),
        createdAt: now,
      ),
    );
    final quizzes = SqliteQuizRepository(database);
    await quizzes.save(
      QuizDefinition(
        id: 'quiz-1',
        sourceDocumentId: 'source-1',
        title: 'Generated quiz',
        questions: [
          QuestionDefinition(
            id: 'question-1',
            prompt: 'Question',
            type: QuestionType.multipleChoice,
            options: const [
              AnswerOption(id: 'a', text: 'One'),
              AnswerOption(id: 'b', text: 'Two'),
            ],
            correctAnswer: 'a',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );

    await sources.delete('source-1');

    expect(await sources.getById('source-1'), isNull);
    expect((await quizzes.getById('quiz-1'))!.sourceDocumentId, isNull);
  });
}
