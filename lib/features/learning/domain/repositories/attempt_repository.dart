import '../entities/learning_entities.dart';

abstract interface class AttemptRepository {
  Future<QuizAttempt?> getLatestInProgress();

  Future<List<QuizAttempt>> getForQuiz(String quizId);

  Future<List<QuizAttempt>> getCompleted();

  Future<void> save(QuizAttempt attempt);

  Future<void> delete(String id);
}
