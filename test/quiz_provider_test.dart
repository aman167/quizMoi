import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/state/quiz_provider.dart';

void main() {
  group('QuizProvider', () {
    test('starts a fresh quiz at the first question and zero time', () {
      final provider = QuizProvider()..startQuiz('test');

      expect(provider.currentQuiz, isNotNull);
      expect(provider.currentQuestionIndex, 0);
      expect(provider.elapsedSeconds, 0);
      expect(provider.formattedTime, '0m 00s');
      expect(provider.quizCompleted, isFalse);
      expect(provider.canAdvance, isFalse);
    });

    test('does not advance until the current question is answered', () {
      final provider = QuizProvider()..startQuiz('test');

      expect(provider.nextQuestion(), isFalse);
      expect(provider.currentQuestionIndex, 0);

      provider.selectOption('b');

      expect(provider.canAdvance, isTrue);
      expect(provider.nextQuestion(), isTrue);
      expect(provider.currentQuestionIndex, 1);
    });

    test('can revisit a question and replace its earlier answer', () {
      final provider = QuizProvider()..startQuiz('test');

      provider.selectOption('a');
      provider.nextQuestion();
      provider.previousQuestion();
      provider.selectOption('b');

      expect(provider.currentQuestionIndex, 0);
      expect(provider.currentQuestion!.selectedOptionId, 'b');
      expect(provider.currentQuestion!.isCorrect, isTrue);
      expect(provider.currentQuiz!.answeredCount, 1);
    });

    test('completes and scores a fully correct quiz', () {
      final provider = QuizProvider()..startQuiz('test');

      while (!provider.quizCompleted) {
        final question = provider.currentQuestion!;
        provider.selectOption(question.correctOptionId);
        expect(provider.nextQuestion(), isTrue);
      }

      expect(provider.currentQuiz!.answeredCount, 10);
      expect(provider.currentQuiz!.correctCount, 10);
      expect(provider.currentQuiz!.incorrectCount, 0);
      expect(provider.currentQuiz!.unansweredCount, 0);
      expect(provider.currentQuiz!.scorePercent, 100);
    });

    test('stops the timer after completion and clears state on reset', () {
      final provider = QuizProvider()..startQuiz('test');
      provider.incrementTimer();
      expect(provider.elapsedSeconds, 1);

      while (!provider.quizCompleted) {
        provider.selectOption(provider.currentQuestion!.correctOptionId);
        provider.nextQuestion();
      }

      provider.incrementTimer();
      expect(provider.elapsedSeconds, 1);

      provider.resetQuiz();
      expect(provider.currentQuiz, isNull);
      expect(provider.elapsedSeconds, 0);
      expect(provider.currentQuestionIndex, 0);
      expect(provider.quizCompleted, isFalse);
    });

    test('counts skipped questions as not earning credit', () {
      final provider = QuizProvider()..startQuiz('test');

      while (provider.currentQuestionIndex < 9) {
        provider.skipQuestion();
      }
      provider.completeQuiz();

      expect(provider.currentQuiz!.correctCount, 0);
      expect(provider.currentQuiz!.incorrectCount, 10);
      expect(provider.currentQuiz!.unansweredCount, 10);
      expect(provider.currentQuiz!.incorrectQuestions, hasLength(10));
    });
  });
}
