import 'package:sqflite/sqflite.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../local/quiz_database.dart';

class SqliteAttemptRepository implements AttemptRepository {
  final QuizDatabase database;

  const SqliteAttemptRepository(this.database);

  @override
  Future<void> delete(String id) async {
    await database.connection.delete(
      'quiz_attempts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<QuizAttempt>> getForQuiz(String quizId) async {
    final rows = await database.connection.query(
      'quiz_attempts',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'started_at DESC',
    );
    return Future.wait(rows.map(_attemptFromRow));
  }

  @override
  Future<List<QuizAttempt>> getCompleted() async {
    final rows = await database.connection.query(
      'quiz_attempts',
      where: 'status = ?',
      whereArgs: [AttemptStatus.completed.name],
      orderBy: 'completed_at DESC',
    );
    return Future.wait(rows.map(_attemptFromRow));
  }

  @override
  Future<QuizAttempt?> getLatestInProgress() async {
    final rows = await database.connection.query(
      'quiz_attempts',
      where: 'status = ?',
      whereArgs: [AttemptStatus.inProgress.name],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _attemptFromRow(rows.single);
  }

  @override
  Future<void> save(QuizAttempt attempt) async {
    await database.connection.transaction((transaction) async {
      final values = <String, Object?>{
        'id': attempt.id,
        'quiz_id': attempt.quizId,
        'status': attempt.status.name,
        'current_question_index': attempt.currentQuestionIndex,
        'elapsed_seconds': attempt.elapsedSeconds,
        'started_at': attempt.startedAt.toIso8601String(),
        'completed_at': attempt.completedAt?.toIso8601String(),
      };
      await transaction.insert(
        'quiz_attempts',
        values,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.update(
        'quiz_attempts',
        values,
        where: 'id = ?',
        whereArgs: [attempt.id],
      );
      await transaction.delete(
        'question_answers',
        where: 'attempt_id = ?',
        whereArgs: [attempt.id],
      );
      for (final answer in attempt.answers) {
        await transaction.insert('question_answers', {
          'attempt_id': attempt.id,
          'question_id': answer.questionId,
          'value': answer.value,
          'answered_at': answer.answeredAt.toIso8601String(),
        });
      }
    });
  }

  Future<QuizAttempt> _attemptFromRow(Map<String, Object?> row) async {
    final answerRows = await database.connection.query(
      'question_answers',
      where: 'attempt_id = ?',
      whereArgs: [row['id']],
      orderBy: 'answered_at ASC',
    );
    return QuizAttempt(
      id: row['id']! as String,
      quizId: row['quiz_id']! as String,
      status: AttemptStatus.values.byName(row['status']! as String),
      answers: answerRows
          .map(
            (answer) => QuestionAnswer(
              questionId: answer['question_id']! as String,
              value: answer['value']! as String,
              answeredAt: DateTime.parse(answer['answered_at']! as String),
            ),
          )
          .toList(),
      currentQuestionIndex: row['current_question_index']! as int,
      elapsedSeconds: row['elapsed_seconds']! as int,
      startedAt: DateTime.parse(row['started_at']! as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at']! as String),
    );
  }
}
