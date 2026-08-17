import 'package:flutter/foundation.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/knowledge_base_repository.dart';

enum KnowledgeBaseLoadState { initial, loading, ready, error }

class KnowledgeBaseProvider extends ChangeNotifier {
  final KnowledgeBaseRepository repository;
  final DateTime Function() _now;

  KnowledgeBaseProvider(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  List<KnowledgeBaseRecord> _allKnowledgeBases = const [];
  KnowledgeBaseLoadState _loadState = KnowledgeBaseLoadState.initial;
  String? _errorMessage;
  bool _showArchived = false;
  int _idCounter = 0;

  List<KnowledgeBaseRecord> get allKnowledgeBases =>
      List.unmodifiable(_allKnowledgeBases);
  List<KnowledgeBaseRecord> get knowledgeBases => List.unmodifiable(
    _allKnowledgeBases.where(
      (knowledgeBase) => _showArchived || !knowledgeBase.isArchived,
    ),
  );
  List<KnowledgeBaseRecord> get activeKnowledgeBases => List.unmodifiable(
    _allKnowledgeBases.where((knowledgeBase) => !knowledgeBase.isArchived),
  );
  KnowledgeBaseLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadState == KnowledgeBaseLoadState.loading;
  bool get showArchived => _showArchived;

  KnowledgeBaseRecord? findById(String? id) {
    if (id == null) return null;
    for (final knowledgeBase in _allKnowledgeBases) {
      if (knowledgeBase.id == id) return knowledgeBase;
    }
    return null;
  }

  bool titleExists(String title, {String? excludingId}) {
    final normalized = title.trim().toLowerCase();
    return _allKnowledgeBases.any(
      (knowledgeBase) =>
          knowledgeBase.id != excludingId &&
          knowledgeBase.title.trim().toLowerCase() == normalized,
    );
  }

  Future<void> load() async {
    _loadState = KnowledgeBaseLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _allKnowledgeBases = await repository.getAll(includeArchived: true);
      _loadState = KnowledgeBaseLoadState.ready;
    } catch (_) {
      _loadState = KnowledgeBaseLoadState.error;
      _errorMessage = 'Knowledge bases could not be loaded.';
    }
    notifyListeners();
  }

  Future<bool> create(String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || titleExists(trimmedTitle)) {
      _errorMessage = trimmedTitle.isEmpty
          ? 'A knowledge-base name is required.'
          : 'A knowledge base with this name already exists.';
      notifyListeners();
      return false;
    }
    final now = _now();
    _idCounter++;
    final knowledgeBase = KnowledgeBaseRecord(
      id: 'knowledge-base-${now.microsecondsSinceEpoch}-$_idCounter',
      title: trimmedTitle,
      sourceDocumentIds: const [],
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    return _save(knowledgeBase);
  }

  Future<bool> rename(KnowledgeBaseRecord knowledgeBase, String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty ||
        titleExists(trimmedTitle, excludingId: knowledgeBase.id)) {
      _errorMessage = trimmedTitle.isEmpty
          ? 'A knowledge-base name is required.'
          : 'A knowledge base with this name already exists.';
      notifyListeners();
      return false;
    }
    return _save(
      knowledgeBase.copyWith(title: trimmedTitle, updatedAt: _now()),
    );
  }

  Future<bool> setArchived(KnowledgeBaseRecord knowledgeBase, bool isArchived) {
    return _save(
      knowledgeBase.copyWith(isArchived: isArchived, updatedAt: _now()),
    );
  }

  Future<bool> attachSource(String knowledgeBaseId, String sourceDocumentId) {
    final knowledgeBase = findById(knowledgeBaseId);
    if (knowledgeBase == null) {
      _errorMessage = 'The selected knowledge base no longer exists.';
      notifyListeners();
      return Future.value(false);
    }
    if (knowledgeBase.sourceDocumentIds.contains(sourceDocumentId)) {
      return Future.value(true);
    }
    return _save(
      knowledgeBase.copyWith(
        sourceDocumentIds: [
          ...knowledgeBase.sourceDocumentIds,
          sourceDocumentId,
        ],
        updatedAt: _now(),
      ),
    );
  }

  Future<bool> delete(String id) async {
    try {
      await repository.delete(id);
      await load();
      return true;
    } catch (_) {
      _errorMessage = 'The knowledge base could not be deleted.';
      notifyListeners();
      return false;
    }
  }

  void setShowArchived(bool value) {
    if (_showArchived == value) return;
    _showArchived = value;
    notifyListeners();
  }

  Future<bool> _save(KnowledgeBaseRecord knowledgeBase) async {
    try {
      await repository.save(knowledgeBase);
      await load();
      return true;
    } catch (_) {
      _errorMessage = 'The knowledge base could not be saved.';
      notifyListeners();
      return false;
    }
  }
}
