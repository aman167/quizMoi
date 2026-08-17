import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';

void main() {
  group('Learning entities', () {
    test('quiz definition survives a JSON round trip', () {
      final quiz = _sampleQuiz();

      final restored = QuizDefinition.fromJson(quiz.toJson());

      expect(restored.toJson(), quiz.toJson());
      expect(restored.questions, isNot(same(quiz.questions)));
    });

    test('attempt and settings survive JSON round trips', () {
      final startedAt = DateTime.utc(2026, 8, 17, 10);
      final attempt = QuizAttempt(
        id: 'attempt-1',
        quizId: 'quiz-1',
        status: AttemptStatus.inProgress,
        answers: [
          QuestionAnswer(
            questionId: 'question-1',
            value: 'b',
            answeredAt: startedAt.add(const Duration(seconds: 12)),
          ),
        ],
        currentQuestionIndex: 1,
        elapsedSeconds: 12,
        startedAt: startedAt,
      );
      const settings = LearnerSettings(
        cefrLevel: 'B1',
        dailyQuestionGoal: 20,
        remindersEnabled: false,
      );

      expect(QuizAttempt.fromJson(attempt.toJson()).toJson(), attempt.toJson());
      expect(
        LearnerSettings.fromJson(settings.toJson()).toJson(),
        settings.toJson(),
      );
    });

    test('rejects an invalid multiple-choice correct answer', () {
      expect(
        () => QuestionDefinition(
          id: 'invalid',
          prompt: 'Choisissez une réponse.',
          type: QuestionType.multipleChoice,
          options: const [
            AnswerOption(id: 'a', text: 'Un'),
            AnswerOption(id: 'b', text: 'Deux'),
          ],
          correctAnswer: 'missing',
        ),
        throwsArgumentError,
      );
    });
  });
}

QuizDefinition _sampleQuiz() {
  final createdAt = DateTime.utc(2026, 8, 17, 9);
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
        concepts: const [
          Concept(
            id: 'daily-vocabulary',
            name: 'Daily vocabulary',
            category: 'Vocabulary',
          ),
        ],
      ),
    ],
  );
}
