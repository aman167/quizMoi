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
import 'package:quiz_moi_app/screens/results_feedback_screen.dart';
import 'package:quiz_moi_app/state/quiz_provider.dart';

Widget _testApp(QuizProvider provider, Widget home) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(home: home),
  );
}

void main() {
  testWidgets('App renders quizMoi dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const QuizMoiApp());
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
}
