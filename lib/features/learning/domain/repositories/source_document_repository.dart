import '../entities/learning_entities.dart';

abstract interface class SourceDocumentRepository {
  Future<List<SourceDocument>> getAll();

  Future<SourceDocument?> getById(String id);

  Future<void> save(SourceDocument source);

  Future<SourceDocument?> findDuplicate(SourceDocument source);

  Future<void> delete(String id);
}
