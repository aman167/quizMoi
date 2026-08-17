import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/learning/presentation/screens/manual_quiz_editor_screen.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/saved_quiz_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/knowledge_base_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/widgets/saved_quiz_library.dart';
import 'package:quiz_moi_app/state/quiz_provider.dart';

Widget _app({
  required QuizProvider quizProvider,
  required SavedQuizProvider savedQuizProvider,
  KnowledgeBaseProvider? knowledgeBaseProvider,
  required Widget home,
}) {
  final effectiveKnowledgeBaseProvider =
      knowledgeBaseProvider ??
      (KnowledgeBaseProvider(MemoryKnowledgeBaseRepository())..load());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: quizProvider),
      ChangeNotifierProvider.value(value: savedQuizProvider),
      ChangeNotifierProvider.value(value: effectiveKnowledgeBaseProvider),
    ],
    child: MaterialApp(home: Scaffold(body: home)),
  );
}

void main() {
  testWidgets('manual editor validates and saves a multiple-choice quiz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final savedProvider = SavedQuizProvider(MemoryQuizRepository());
    final knowledgeBaseProvider = KnowledgeBaseProvider(
      MemoryKnowledgeBaseRepository(
        initialKnowledgeBases: [_knowledgeBase(DateTime.now())],
      ),
    );
    await savedProvider.load();
    await knowledgeBaseProvider.load();
    await tester.pumpWidget(
      _app(
        quizProvider: QuizProvider(),
        savedQuizProvider: savedProvider,
        knowledgeBaseProvider: knowledgeBaseProvider,
        home: const ManualQuizEditorScreen(),
      ),
    );

    await tester.ensureVisible(find.text('Save Quiz'));
    await tester.tap(find.text('Save Quiz'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(6));

    const values = [
      'Travel French',
      'Que signifie bonjour ?',
      'Hello',
      'Goodbye',
      'Please',
      'Thanks',
    ];
    final fields = find.byType(TextFormField);
    for (var index = 0; index < values.length; index++) {
      await tester.enterText(fields.at(index), values[index]);
    }
    await tester.tap(find.text('Unfiled'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Travel Lessons').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Quiz'));
    await tester.tap(find.text('Save Quiz'));
    await tester.pumpAndSettle();

    expect(savedProvider.quizzes, hasLength(1));
    expect(savedProvider.quizzes.single.title, 'Travel French');
    expect(savedProvider.quizzes.single.knowledgeBaseId, 'knowledge-base-1');
    expect(savedProvider.quizzes.single.questions.single.options, hasLength(4));
  });

  testWidgets('saved library launches a stored quiz in the testing engine', (
    tester,
  ) async {
    final timestamp = DateTime.utc(2026, 8, 17, 12);
    final repository = MemoryQuizRepository(initialQuizzes: [_quiz(timestamp)]);
    final savedProvider = SavedQuizProvider(repository);
    final knowledgeBaseProvider = KnowledgeBaseProvider(
      MemoryKnowledgeBaseRepository(
        initialKnowledgeBases: [_knowledgeBase(timestamp)],
      ),
    );
    final quizProvider = QuizProvider();
    await savedProvider.load();
    await knowledgeBaseProvider.load();
    await tester.pumpWidget(
      _app(
        quizProvider: quizProvider,
        savedQuizProvider: savedProvider,
        knowledgeBaseProvider: knowledgeBaseProvider,
        home: const SingleChildScrollView(child: SavedQuizLibrary()),
      ),
    );

    final quizTitle = find.text('Travel French');
    await tester.ensureVisible(quizTitle);
    expect(find.text('Knowledge base: Travel Lessons'), findsOneWidget);
    final card = find.ancestor(of: quizTitle, matching: find.byType(Card));
    await tester.tap(find.descendant(of: card, matching: find.text('Test Me')));
    await tester.pumpAndSettle();

    expect(quizProvider.currentQuiz!.title, 'Travel French');
    expect(find.text('Que signifie bonjour ?'), findsOneWidget);
  });
}

QuizDefinition _quiz(DateTime timestamp) => QuizDefinition(
  id: 'quiz-1',
  knowledgeBaseId: 'knowledge-base-1',
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
        AnswerOption(id: 'c', text: 'Please'),
        AnswerOption(id: 'd', text: 'Thanks'),
      ],
      correctAnswer: 'a',
    ),
  ],
);

KnowledgeBaseRecord _knowledgeBase(DateTime timestamp) => KnowledgeBaseRecord(
  id: 'knowledge-base-1',
  title: 'Travel Lessons',
  sourceDocumentIds: const [],
  isArchived: false,
  createdAt: timestamp,
  updatedAt: timestamp,
);
