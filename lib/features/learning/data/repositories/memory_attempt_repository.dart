import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/attempt_repository.dart';

class MemoryAttemptRepository implements AttemptRepository {
  final Map<String, QuizAttempt> _attempts = {};

  MemoryAttemptRepository({Iterable<QuizAttempt> initialAttempts = const []}) {
    for (final attempt in initialAttempts) {
      _attempts[attempt.id] = attempt;
    }
  }

  @override
  Future<void> delete(String id) async {
    _attempts.remove(id);
  }

  @override
  Future<List<QuizAttempt>> getForQuiz(String quizId) async {
    final attempts =
        _attempts.values.where((attempt) => attempt.quizId == quizId).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return attempts;
  }

  @override
  Future<List<QuizAttempt>> getCompleted() async {
    final attempts =
        _attempts.values
            .where((attempt) => attempt.status == AttemptStatus.completed)
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.startedAt).compareTo(
              a.completedAt ?? a.startedAt,
            ),
          );
    return attempts;
  }

  @override
  Future<QuizAttempt?> getLatestInProgress() async {
    final attempts =
        _attempts.values
            .where((attempt) => attempt.status == AttemptStatus.inProgress)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return attempts.firstOrNull;
  }

  @override
  Future<void> save(QuizAttempt attempt) async {
    _attempts[attempt.id] = attempt;
  }
}
