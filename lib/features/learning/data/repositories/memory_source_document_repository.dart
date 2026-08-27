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
  Future<SourceDocument?> findDuplicate(SourceDocument source) async {
    return _sources.values.cast<SourceDocument?>().firstWhere(
      (candidate) =>
          candidate!.id != source.id && _sameSource(candidate, source),
      orElse: () => null,
    );
  }

  @override
  Future<void> save(SourceDocument source) async {
    _sources[source.id] = source;
  }
}

bool _sameSource(SourceDocument left, SourceDocument right) {
  if (left.type != right.type) return false;
  if (left.sourceUri != null && right.sourceUri != null) {
    return left.sourceUri!.trim().toLowerCase() ==
        right.sourceUri!.trim().toLowerCase();
  }
  String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return normalize(left.content) == normalize(right.content);
}
