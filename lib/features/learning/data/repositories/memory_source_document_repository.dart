import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/source_document_repository.dart';

class MemorySourceDocumentRepository implements SourceDocumentRepository {
  final Map<String, SourceDocument> _sources = {};

  MemorySourceDocumentRepository({
    Iterable<SourceDocument> initialSources = const [],
  }) {
    for (final source in initialSources) {
      _sources[source.id] = source;
    }
  }

  @override
  Future<void> delete(String id) async {
    _sources.remove(id);
  }

  @override
  Future<List<SourceDocument>> getAll() async {
    final sources = _sources.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sources;
  }

  @override
  Future<SourceDocument?> getById(String id) async => _sources[id];

  @override
  Future<void> save(SourceDocument source) async {
    _sources[source.id] = source;
  }
}
