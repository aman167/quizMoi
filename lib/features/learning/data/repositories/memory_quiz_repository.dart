import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/quiz_repository.dart';

class MemoryQuizRepository implements QuizRepository {
  final Map<String, QuizDefinition> _quizzes = {};

  MemoryQuizRepository({Iterable<QuizDefinition> initialQuizzes = const []}) {
    for (final quiz in initialQuizzes) {
      _quizzes[quiz.id] = quiz;
    }
  }

  @override
  Future<void> delete(String id) async {
    _quizzes.remove(id);
  }

  @override
  Future<List<QuizDefinition>> getAll({bool includeArchived = false}) async {
    final quizzes =
        _quizzes.values
            .where((quiz) => includeArchived || !quiz.isArchived)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return quizzes;
  }

  @override
  Future<QuizDefinition?> getById(String id) async => _quizzes[id];

  @override
  Future<void> save(QuizDefinition quiz) async {
    _quizzes[quiz.id] = quiz;
  }
}
