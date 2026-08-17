// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_moi_app/main.dart';
import 'package:quiz_moi_app/screens/active_testing_screen.dart';
import 'package:quiz_moi_app/screens/dashboard_screen.dart';
import 'package:quiz_moi_app/screens/results_feedback_screen.dart';
import 'package:quiz_moi_app/screens/upload_content_screen.dart';
import 'package:quiz_moi_app/state/quiz_provider.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_attempt_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_learner_settings_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_source_document_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/learning/domain/repositories/source_document_repository.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/saved_quiz_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/attempt_history_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/knowledge_base_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/learner_settings_provider.dart';
import 'package:quiz_moi_app/features/quiz_generation/presentation/state/quiz_generation_provider.dart';

import 'support/fake_quiz_generation_gateway.dart';

Widget _testApp(
  QuizProvider provider,
  Widget home, {
  TextScaler textScaler = TextScaler.noScaling,
  SavedQuizProvider? savedQuizProvider,
  AttemptHistoryProvider? attemptHistoryProvider,
  LearnerSettingsProvider? learnerSettingsProvider,
}) {
  final savedProvider =
      savedQuizProvider ?? SavedQuizProvider(MemoryQuizRepository())
        ..load();
  final historyProvider =
      attemptHistoryProvider ??
      (AttemptHistoryProvider(
        attemptRepository: MemoryAttemptRepository(),
        quizRepository: savedProvider.repository,
      )..load());
  final knowledgeBaseProvider = KnowledgeBaseProvider(
    MemoryKnowledgeBaseRepository(),
  )..load();
  final effectiveLearnerSettingsProvider =
      learnerSettingsProvider ??
      (LearnerSettingsProvider(MemoryLearnerSettingsRepository())..load());
  return MultiProvider(
    providers: [
      Provider<SourceDocumentRepository>.value(
        value: MemorySourceDocumentRepository(),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            QuizGenerationProvider(gateway: FakeQuizGenerationGateway()),
      ),
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(value: savedProvider),
      ChangeNotifierProvider.value(value: historyProvider),
      ChangeNotifierProvider.value(value: knowledgeBaseProvider),
      ChangeNotifierProvider.value(value: effectiveLearnerSettingsProvider),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: home,
    ),
  );
}

void main() {
  testWidgets('App renders quizMoi dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(QuizMoiApp(quizRepository: MemoryQuizRepository()));
    expect(find.text('quizMoi'), findsWidgets);
  });

  testWidgets('Stats shows an empty state before a quiz is completed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(QuizProvider(), const ResultsFeedbackScreen()),
    );

    expect(find.text('No quiz results yet'), findsOneWidget);
    expect(
      find.text(
        'Complete a quiz and your score and feedback will appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Dashboard derives level, goal, and streak from local data', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final quiz = _savedQuiz(now);
    final quizRepository = MemoryQuizRepository(initialQuizzes: [quiz]);
    final savedProvider = SavedQuizProvider(quizRepository);
    await savedProvider.load();
    final historyProvider = AttemptHistoryProvider(
      attemptRepository: MemoryAttemptRepository(
        initialAttempts: [
          QuizAttempt(
            id: 'attempt-completed',
            quizId: quiz.id,
            status: AttemptStatus.completed,
            answers: [
              QuestionAnswer(
                questionId: 'question-1',
                value: 'a',
                answeredAt: now,
              ),
              QuestionAnswer(
                questionId: 'question-2',
                value: 'b',
                answeredAt: now,
              ),
            ],
            currentQuestionIndex: 1,
            elapsedSeconds: 20,
            startedAt: now.subtract(const Duration(seconds: 20)),
            completedAt: now,
          ),
        ],
      ),
      quizRepository: quizRepository,
      now: () => now,
    );
    await historyProvider.load();
    final settingsProvider = LearnerSettingsProvider(
      MemoryLearnerSettingsRepository(
        initialSettings: const LearnerSettings(
          cefrLevel: 'B2',
          dailyQuestionGoal: 10,
          remindersEnabled: false,
        ),
      ),
    );
    await settingsProvider.load();

    await tester.pumpWidget(
      _testApp(
        QuizProvider(),
        const DashboardScreen(),
        savedQuizProvider: savedProvider,
        attemptHistoryProvider: historyProvider,
        learnerSettingsProvider: settingsProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('B2 French'), findsOneWidget);
    expect(find.text('2 / 10 Questions'), findsOneWidget);
    expect(find.text('1 Day Streak!'), findsOneWidget);
  });

  testWidgets('Quiz requires an answer before moving to the next question', (
    WidgetTester tester,
  ) async {
    final provider = QuizProvider()..startQuiz('test');
    await tester.pumpWidget(_testApp(provider, const ActiveTestingScreen()));

    expect(find.text('0m 00s'), findsOneWidget);

    final nextButton = find.ancestor(
      of: find.text('Next'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);

    await tester.tap(find.text('Journalier'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);
  });

  testWidgets('Restart asks for confirmation', (WidgetTester tester) async {
    final provider = QuizProvider()..startQuiz('test');
    await tester.pumpWidget(_testApp(provider, const ActiveTestingScreen()));

    await tester.tap(find.byTooltip('Restart Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Restart this quiz?'), findsOneWidget);
    expect(
      find.text('All selected answers and the elapsed time will be reset.'),
      findsOneWidget,
    );
  });

  testWidgets('Exit asks for confirmation and cancel keeps the quiz open', (
    WidgetTester tester,
  ) async {
    final provider = QuizProvider()..startQuiz('test');
    await tester.pumpWidget(_testApp(provider, const ActiveTestingScreen()));

    await tester.tap(find.text('Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Leave this quiz?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 10'), findsOneWidget);
    expect(provider.currentQuiz, isNotNull);
  });

  testWidgets('Ten-question journey confirms submission and shows results', (
    WidgetTester tester,
  ) async {
    final provider = QuizProvider()..startQuiz('test');
    await tester.pumpWidget(_testApp(provider, const ActiveTestingScreen()));

    for (var question = 1; question <= 10; question++) {
      final answerText = provider.currentQuestion!.options.first.text;
      await tester.ensureVisible(find.text(answerText));
      await tester.tap(find.text(answerText));
      await tester.pump();

      final actionLabel = question == 10 ? 'Submit' : 'Next';
      await tester.tap(find.text(actionLabel));
      await tester.pumpAndSettle();
    }

    expect(find.text('Submit this quiz?'), findsOneWidget);
    expect(provider.quizCompleted, isFalse);

    await tester.tap(find.text('Submit quiz'));
    await tester.pumpAndSettle();

    expect(provider.quizCompleted, isTrue);
    expect(find.text('Quiz Results'), findsOneWidget);
    expect(find.text('10 of 10 questions correct'), findsNothing);
  });

  testWidgets('Previous navigation preserves and allows changing an answer', (
    WidgetTester tester,
  ) async {
    final provider = QuizProvider()..startQuiz('test');
    await tester.pumpWidget(_testApp(provider, const ActiveTestingScreen()));

    await tester.tap(find.text('Rare'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journalier'));
    await tester.pump();

    expect(provider.currentQuestionIndex, 0);
    expect(provider.currentQuestion!.selectedOptionId, 'b');
    expect(provider.currentQuestion!.isCorrect, isTrue);
  });

  testWidgets('Quiz controls fit a narrow Android screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = QuizProvider()..startQuiz('test');
    await tester.pumpWidget(_testApp(provider, const ActiveTestingScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('0 of 10 answered'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Navigation opens locally stored learner settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(QuizMoiApp(quizRepository: MemoryQuizRepository()));

    expect(find.bySemanticsLabel('Review tab'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Account tab'));
    await tester.pumpAndSettle();

    expect(find.text('Local learner profile'), findsOneWidget);
    expect(find.text('Current French level'), findsOneWidget);
    expect(find.text('Daily question goal'), findsOneWidget);
  });

  testWidgets('App startup offers and opens a restored quiz session', (
    WidgetTester tester,
  ) async {
    final timestamp = DateTime.utc(2026, 8, 17, 14);
    final quiz = _savedQuiz(timestamp);
    final attempt = QuizAttempt(
      id: 'attempt-1',
      quizId: quiz.id,
      status: AttemptStatus.inProgress,
      answers: [
        QuestionAnswer(
          questionId: 'question-1',
          value: 'a',
          answeredAt: timestamp.add(const Duration(seconds: 5)),
        ),
      ],
      currentQuestionIndex: 1,
      elapsedSeconds: 12,
      startedAt: timestamp,
    );
    await tester.pumpWidget(
      QuizMoiApp(
        quizRepository: MemoryQuizRepository(initialQuizzes: [quiz]),
        attemptRepository: MemoryAttemptRepository(initialAttempts: [attempt]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quiz in progress'), findsOneWidget);
    expect(find.text('Travel French • 1 of 2 answered'), findsOneWidget);
    await tester.tap(find.text('Resume Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Que signifie au revoir ?'), findsOneWidget);
    expect(find.text('0m 12s'), findsOneWidget);
  });

  testWidgets('Learn input accepts multiline keyboard text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(QuizProvider(), const UploadContentScreen()),
    );

    final input = find.byType(TextField);
    await tester.ensureVisible(input);
    await tester.pumpAndSettle();
    await tester.tap(input);
    await tester.enterText(input, 'Bonjour\nComment allez-vous ?');
    await tester.pump();

    expect(find.text('Bonjour\nComment allez-vous ?'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pasted text reaches generated review, save, and quiz launch', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = QuizProvider();
    await tester.pumpWidget(_testApp(provider, const UploadContentScreen()));
    final sourceText = List.filled(
      12,
      'Marie prend le train chaque matin pour aller à son travail.',
    ).join(' ');
    await tester.enterText(find.byType(TextField), sourceText);
    await tester.ensureVisible(find.text('Preview & Generate'));
    await tester.tap(find.text('Preview & Generate'));
    await tester.pumpAndSettle();

    expect(find.text('Preview your source'), findsOneWidget);
    expect(find.textContaining('10 multiple-choice questions'), findsOneWidget);
    await tester.tap(find.text('Generate Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Review Generated Quiz'), findsOneWidget);
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Regenerate All Questions'), findsOneWidget);
    await tester.tap(find.text('Save Quiz'));
    await tester.pumpAndSettle();

    expect(provider.currentQuiz, isNotNull);
    expect(provider.currentQuiz!.title, 'Le trajet de Marie');
    expect(
      find.text('Question 1: comment Marie voyage-t-elle ?'),
      findsOneWidget,
    );
  });

  testWidgets('Generated results use persisted explanation and concepts', (
    WidgetTester tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17, 20);
    final generatedQuiz = QuizDefinition(
      id: 'generated-quiz',
      sourceDocumentId: 'source-1',
      title: 'Generated travel quiz',
      createdAt: now,
      updatedAt: now,
      questions: [
        QuestionDefinition(
          id: 'generated-question',
          prompt: 'Comment Marie voyage-t-elle ?',
          type: QuestionType.multipleChoice,
          options: const [
            AnswerOption(id: 'a', text: 'En train'),
            AnswerOption(id: 'b', text: 'En avion'),
          ],
          correctAnswer: 'a',
          explanation: const QuestionExplanation(
            text: 'Le texte indique que Marie prend le train.',
            sourceExcerpt: 'Marie prend le train chaque matin.',
          ),
          concepts: const [
            Concept(
              id: 'transport',
              name: 'Les transports',
              category: 'vocabulary',
            ),
          ],
        ),
      ],
    );
    final provider = QuizProvider()..startSavedQuiz(generatedQuiz);
    provider.selectOption('b');
    provider.nextQuestion();

    await tester.pumpWidget(_testApp(provider, const ResultsFeedbackScreen()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Le texte indique que Marie prend le train.'),
      findsOneWidget,
    );
    expect(find.text('Les transports'), findsOneWidget);
    expect(find.text('Review area: vocabulary'), findsOneWidget);
  });

  testWidgets('Main screens support narrow phones with enlarged text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = QuizProvider();
    final screens = <String, Widget>{
      'Learn': const UploadContentScreen(),
      'Dashboard': const DashboardScreen(),
      'Results': const ResultsFeedbackScreen(),
      'Account': const AccountScreen(),
    };

    for (final entry in screens.entries) {
      await tester.pumpWidget(
        _testApp(
          provider,
          entry.value,
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${entry.key} should not overflow with enlarged text.',
      );
    }
  });
}

QuizDefinition _savedQuiz(DateTime timestamp) => QuizDefinition(
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
