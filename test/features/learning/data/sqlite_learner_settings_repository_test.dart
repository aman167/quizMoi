import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_learner_settings_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late QuizDatabase database;
  late SqliteLearnerSettingsRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = SqliteLearnerSettingsRepository(database);
  });

  tearDown(() => database.close());

  test('returns empty, then saves and updates local settings', () async {
    expect(await repository.get(), isNull);

    const initial = LearnerSettings(
      cefrLevel: 'B1',
      dailyQuestionGoal: 20,
      remindersEnabled: false,
    );
    await repository.save(initial);
    expect((await repository.get())!.toJson(), initial.toJson());

    final updated = initial.copyWith(
      cefrLevel: 'B2',
      dailyQuestionGoal: 30,
      remindersEnabled: true,
    );
    await repository.save(updated);
    expect((await repository.get())!.toJson(), updated.toJson());
  });
}
