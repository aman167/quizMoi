import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_attempt_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_learner_settings_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/attempt_history_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/knowledge_base_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/learner_settings_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/saved_quiz_provider.dart';
import 'package:quiz_moi_app/state/quiz_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'quiz-moi-restart-',
    );
    databasePath = path.join(temporaryDirectory.path, 'learning.sqlite');
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'create, reopen, complete, and reopen history survives restarts',
    () async {
      final now = DateTime(2026, 8, 17, 17);

      final firstDatabase = await QuizDatabase.open(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      final knowledgeBaseProvider = KnowledgeBaseProvider(
        SqliteKnowledgeBaseRepository(firstDatabase),
        now: () => now,
      );
      await knowledgeBaseProvider.load();
      expect(await knowledgeBaseProvider.create('Travel Lessons'), isTrue);
      final knowledgeBase = knowledgeBaseProvider.knowledgeBases.single;
      final firstQuizRepository = SqliteQuizRepository(firstDatabase);
      final savedQuizProvider = SavedQuizProvider(firstQuizRepository);
      await savedQuizProvider.load();
      expect(
        await savedQuizProvider.save(_quiz(now, knowledgeBase.id)),
        isTrue,
      );
      final firstSettingsProvider = LearnerSettingsProvider(
        SqliteLearnerSettingsRepository(firstDatabase),
      );
      await firstSettingsProvider.load();
      await firstSettingsProvider.update(
        cefrLevel: 'B2',
        dailyQuestionGoal: 30,
      );
      await firstDatabase.close();

      final secondDatabase = await QuizDatabase.open(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      final secondQuizRepository = SqliteQuizRepository(secondDatabase);
      final restoredQuiz = await secondQuizRepository.getById('quiz-1');
      expect(restoredQuiz, isNotNull);
      final quizProvider = QuizProvider(
        attemptRepository: SqliteAttemptRepository(secondDatabase),
        now: () => now,
      );
      quizProvider.startSavedQuiz(restoredQuiz!);
      quizProvider.selectOption('a');
      expect(quizProvider.nextQuestion(), isTrue);
      await quizProvider.persistSession();
      await secondDatabase.close();

      final thirdDatabase = await QuizDatabase.open(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(thirdDatabase.close);
      final thirdQuizRepository = SqliteQuizRepository(thirdDatabase);
      final historyProvider = AttemptHistoryProvider(
        attemptRepository: SqliteAttemptRepository(thirdDatabase),
        quizRepository: thirdQuizRepository,
        now: () => now,
      );
      await historyProvider.load();
      final restoredSettings = await SqliteLearnerSettingsRepository(
        thirdDatabase,
      ).get();

      expect(historyProvider.completedAttemptCount, 1);
      expect(historyProvider.accuracyPercent, 100);
      expect(historyProvider.questionsCompletedToday, 1);
      expect(historyProvider.currentStreakDays, 1);
      expect(restoredSettings!.cefrLevel, 'B2');
      expect(restoredSettings.dailyQuestionGoal, 30);
    },
  );
}

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
