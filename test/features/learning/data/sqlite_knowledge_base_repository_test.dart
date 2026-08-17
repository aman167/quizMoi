import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late QuizDatabase database;
  late SqliteKnowledgeBaseRepository repository;
  late DateTime now;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = SqliteKnowledgeBaseRepository(database);
    now = DateTime.utc(2026, 8, 17, 16);
  });

  tearDown(() => database.close());

  test(
    'saves, updates, and archive-filters a complete knowledge base',
    () async {
      await database.connection.insert('source_documents', {
        'id': 'source-1',
        'title': 'Travel notes',
        'source_type': SourceType.manual.name,
        'content': 'Bonjour',
        'created_at': now.toIso8601String(),
      });
      final knowledgeBase = _knowledgeBase(now, sourceIds: const ['source-1']);

      await repository.save(knowledgeBase);
      final restored = await repository.getById(knowledgeBase.id);

      expect(restored!.toJson(), knowledgeBase.toJson());

      final archived = knowledgeBase.copyWith(
        title: 'Travel French',
        isArchived: true,
        updatedAt: now.add(const Duration(minutes: 1)),
      );
      await repository.save(archived);

      expect(await repository.getAll(), isEmpty);
      expect(
        (await repository.getAll(includeArchived: true)).single.toJson(),
        archived.toJson(),
      );
    },
  );

  test(
    'deleting a knowledge base keeps its quizzes and unfiles them',
    () async {
      final knowledgeBase = _knowledgeBase(now);
      await repository.save(knowledgeBase);
      final quizRepository = SqliteQuizRepository(database);
      await quizRepository.save(_quiz(now, knowledgeBase.id));

      await repository.delete(knowledgeBase.id);

      expect(await repository.getById(knowledgeBase.id), isNull);
      final quiz = await quizRepository.getById('quiz-1');
      expect(quiz, isNotNull);
      expect(quiz!.knowledgeBaseId, isNull);
    },
  );
}

KnowledgeBaseRecord _knowledgeBase(
  DateTime timestamp, {
  List<String> sourceIds = const [],
}) => KnowledgeBaseRecord(
  id: 'knowledge-base-1',
  title: 'Travel Lessons',
  sourceDocumentIds: sourceIds,
  isArchived: false,
  createdAt: timestamp,
  updatedAt: timestamp,
);

QuizDefinition _quiz(DateTime timestamp, String knowledgeBaseId) =>
    QuizDefinition(
      id: 'quiz-1',
      knowledgeBaseId: knowledgeBaseId,
      title: 'Travel Quiz',
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
