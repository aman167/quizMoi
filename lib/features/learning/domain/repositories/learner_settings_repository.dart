import '../entities/learning_entities.dart';

abstract interface class LearnerSettingsRepository {
  Future<LearnerSettings?> get();

  Future<void> save(LearnerSettings settings);
}
