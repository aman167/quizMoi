import 'package:sqflite/sqflite.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/learner_settings_repository.dart';
import '../local/quiz_database.dart';

class SqliteLearnerSettingsRepository implements LearnerSettingsRepository {
  final QuizDatabase database;

  const SqliteLearnerSettingsRepository(this.database);

  @override
  Future<LearnerSettings?> get() async {
    final rows = await database.connection.query(
      'learner_settings',
      where: 'id = ?',
      whereArgs: ['local-learner'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return LearnerSettings(
      id: row['id']! as String,
      cefrLevel: row['cefr_level']! as String,
      dailyQuestionGoal: row['daily_question_goal']! as int,
      remindersEnabled: (row['reminders_enabled']! as int) == 1,
    );
  }

  @override
  Future<void> save(LearnerSettings settings) async {
    await database.connection.insert('learner_settings', {
      'id': settings.id,
      'cefr_level': settings.cefrLevel,
      'daily_question_goal': settings.dailyQuestionGoal,
      'reminders_enabled': settings.remindersEnabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
