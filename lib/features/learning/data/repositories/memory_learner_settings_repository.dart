import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/learner_settings_repository.dart';

class MemoryLearnerSettingsRepository implements LearnerSettingsRepository {
  LearnerSettings? _settings;

  MemoryLearnerSettingsRepository({LearnerSettings? initialSettings})
    : _settings = initialSettings;

  @override
  Future<LearnerSettings?> get() async => _settings;

  @override
  Future<void> save(LearnerSettings settings) async {
    _settings = settings;
  }
}
