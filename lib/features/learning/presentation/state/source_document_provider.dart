import 'package:flutter/foundation.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/source_document_repository.dart';

class SourceDocumentProvider extends ChangeNotifier {
  final SourceDocumentRepository repository;

  SourceDocumentProvider(this.repository);

  List<SourceDocument> _sources = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SourceDocument> get sources => _sources;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _sources = await repository.getAll();
    } catch (_) {
      _errorMessage = 'Saved sources could not be loaded.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> delete(String id) async {
    try {
      await repository.delete(id);
      await load();
      return true;
    } catch (_) {
      _errorMessage = 'The source could not be deleted.';
      notifyListeners();
      return false;
    }
  }
}
