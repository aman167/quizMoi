import '../entities/learning_entities.dart';

abstract interface class QuizRepository {
  Future<List<QuizDefinition>> getAll({bool includeArchived = false});

  Future<QuizDefinition?> getById(String id);

  Future<void> save(QuizDefinition quiz);

  Future<void> delete(String id);
}
