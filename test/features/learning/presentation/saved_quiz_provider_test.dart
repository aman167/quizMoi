import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/saved_quiz_provider.dart';

void main() {
  test(
    'save, duplicate, archive, restore, and delete update the library',
    () async {
      final now = DateTime.utc(2026, 8, 17, 12);
      final provider = SavedQuizProvider(
        MemoryQuizRepository(),
        now: () => now,
      );
      final quiz = _quiz(now);

      expect(await provider.save(quiz), isTrue);
      expect(provider.quizzes.single.title, 'Travel French');

      expect(await provider.duplicate(quiz), isTrue);
      expect(provider.quizzes, hasLength(2));
      expect(
        provider.quizzes.any((item) => item.title == 'Travel French (Copy)'),
        isTrue,
      );

      expect(await provider.setArchived(quiz, true), isTrue);
      expect(provider.quizzes, hasLength(1));

      await provider.setShowArchived(true);
      final archived = provider.quizzes.firstWhere(
        (item) => item.id == quiz.id,
      );
      expect(archived.isArchived, isTrue);

      expect(await provider.setArchived(archived, false), isTrue);
      expect(
        provider.quizzes.firstWhere((item) => item.id == quiz.id).isArchived,
        isFalse,
      );

      expect(await provider.deleteQuiz(quiz.id), isTrue);
      expect(provider.quizzes.any((item) => item.id == quiz.id), isFalse);
    },
  );
}

QuizDefinition _quiz(DateTime timestamp) => QuizDefinition(
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
        AnswerOption(id: 'c', text: 'Please'),
        AnswerOption(id: 'd', text: 'Thanks'),
      ],
      correctAnswer: 'a',
    ),
  ],
);
