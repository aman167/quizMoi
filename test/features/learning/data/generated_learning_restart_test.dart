import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_source_document_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'quiz-moi-generated-restart-',
    );
    databasePath = path.join(temporaryDirectory.path, 'generated.sqlite');
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'generated source, quiz, evidence, and folder survive restart',
    () async {
      final now = DateTime.utc(2026, 8, 17, 21);
      final source = SourceDocument(
        id: 'source-1',
        title: 'Le trajet de Marie',
        type: SourceType.webArticle,
        content: List.filled(
          12,
          'Marie prend le train chaque matin pour aller à son travail.',
        ).join(' '),
        sourceUri: 'https://example.com/fr/le-trajet-de-marie',
        createdAt: now,
      );
      final knowledgeBase = KnowledgeBaseRecord(
        id: 'knowledge-base-1',
        title: 'Daily French',
        sourceDocumentIds: [source.id],
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
      final quiz = QuizDefinition(
        id: 'quiz-1',
        knowledgeBaseId: knowledgeBase.id,
        sourceDocumentId: source.id,
        title: 'Le trajet de Marie',
        questions: [
          QuestionDefinition(
            id: 'question-1',
            prompt: 'Comment Marie voyage-t-elle ?',
            type: QuestionType.multipleChoice,
            options: const [
              AnswerOption(id: 'a', text: 'En train'),
              AnswerOption(id: 'b', text: 'En avion'),
              AnswerOption(id: 'c', text: 'À vélo'),
              AnswerOption(id: 'd', text: 'À pied'),
            ],
            correctAnswer: 'a',
            explanation: const QuestionExplanation(
              text: 'Marie utilise le train.',
              sourceExcerpt: 'Marie prend le train chaque matin',
            ),
            concepts: const [
              Concept(
                id: 'concept-1',
                name: 'Les transports',
                category: 'vocabulary',
              ),
            ],
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final firstDatabase = await QuizDatabase.open(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await SqliteSourceDocumentRepository(firstDatabase).save(source);
      await SqliteKnowledgeBaseRepository(firstDatabase).save(knowledgeBase);
      await SqliteQuizRepository(firstDatabase).save(quiz);
      await firstDatabase.close();

      final reopened = await QuizDatabase.open(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(reopened.close);
      final restoredSource = await SqliteSourceDocumentRepository(
        reopened,
      ).getById(source.id);
      final restoredKnowledgeBase = await SqliteKnowledgeBaseRepository(
        reopened,
      ).getById(knowledgeBase.id);
      final restoredQuiz = await SqliteQuizRepository(
        reopened,
      ).getById(quiz.id);

      expect(restoredSource!.content, source.content);
      expect(restoredSource.sourceUri, source.sourceUri);
      expect(restoredSource.type, SourceType.webArticle);
      expect(restoredKnowledgeBase!.sourceDocumentIds, contains(source.id));
      expect(restoredQuiz!.sourceDocumentId, source.id);
      expect(
        restoredQuiz.questions.single.explanation!.sourceExcerpt,
        'Marie prend le train chaque matin',
      );
      expect(
        restoredQuiz.questions.single.concepts.single.name,
        'Les transports',
      );
    },
  );
}
