import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/knowledge_base_repository.dart';

class MemoryKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final Map<String, KnowledgeBaseRecord> _knowledgeBases = {};

  MemoryKnowledgeBaseRepository({
    Iterable<KnowledgeBaseRecord> initialKnowledgeBases = const [],
  }) {
    for (final knowledgeBase in initialKnowledgeBases) {
      _knowledgeBases[knowledgeBase.id] = knowledgeBase;
    }
  }

  @override
  Future<void> delete(String id) async {
    _knowledgeBases.remove(id);
  }

  @override
  Future<List<KnowledgeBaseRecord>> getAll({
    bool includeArchived = false,
  }) async {
    final knowledgeBases =
        _knowledgeBases.values
            .where(
              (knowledgeBase) => includeArchived || !knowledgeBase.isArchived,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return knowledgeBases;
  }

  @override
  Future<KnowledgeBaseRecord?> getById(String id) async => _knowledgeBases[id];

  @override
  Future<void> save(KnowledgeBaseRecord knowledgeBase) async {
    _knowledgeBases[knowledgeBase.id] = knowledgeBase;
  }
}
