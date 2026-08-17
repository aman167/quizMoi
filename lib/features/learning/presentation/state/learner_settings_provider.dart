import 'package:flutter/foundation.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/learner_settings_repository.dart';

enum LearnerSettingsLoadState { initial, loading, ready, error }

class LearnerSettingsProvider extends ChangeNotifier {
  static const defaultSettings = LearnerSettings(
    cefrLevel: 'B1',
    dailyQuestionGoal: 20,
    remindersEnabled: false,
  );

  final LearnerSettingsRepository repository;

  LearnerSettingsProvider(this.repository);

  LearnerSettings _settings = defaultSettings;
  LearnerSettingsLoadState _loadState = LearnerSettingsLoadState.initial;
  String? _errorMessage;
  bool _isSaving = false;

  LearnerSettings get settings => _settings;
  LearnerSettingsLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadState == LearnerSettingsLoadState.loading;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    _loadState = LearnerSettingsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final storedSettings = await repository.get();
      if (storedSettings == null) {
        await repository.save(defaultSettings);
        _settings = defaultSettings;
      } else {
        _settings = storedSettings;
      }
      _loadState = LearnerSettingsLoadState.ready;
    } catch (_) {
      _loadState = LearnerSettingsLoadState.error;
      _errorMessage = 'Your learning settings could not be loaded.';
    }
    notifyListeners();
  }

  Future<bool> update({
    String? cefrLevel,
    int? dailyQuestionGoal,
    bool? remindersEnabled,
  }) async {
    final updated = _settings.copyWith(
      cefrLevel: cefrLevel,
      dailyQuestionGoal: dailyQuestionGoal,
      remindersEnabled: remindersEnabled,
    );
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.save(updated);
      _settings = updated;
      _loadState = LearnerSettingsLoadState.ready;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Your learning settings could not be saved.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
