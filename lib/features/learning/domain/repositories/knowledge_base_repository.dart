import '../entities/learning_entities.dart';

abstract interface class KnowledgeBaseRepository {
  Future<List<KnowledgeBaseRecord>> getAll({bool includeArchived = false});

  Future<KnowledgeBaseRecord?> getById(String id);

  Future<void> save(KnowledgeBaseRecord knowledgeBase);

  Future<void> delete(String id);
}
