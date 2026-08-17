import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:quiz_moi_app/features/learning/data/local/quiz_database.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/sqlite_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'quiz-moi-migration-',
    );
    databasePath = path.join(temporaryDirectory.path, 'migration.sqlite');
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('upgrades version 1 without losing stored knowledge bases', () async {
    final timestamp = DateTime.utc(2026, 8, 17, 17);
    final versionOne = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
      schemaVersionOverride: 1,
    );
    await SqliteKnowledgeBaseRepository(versionOne).save(
      KnowledgeBaseRecord(
        id: 'knowledge-base-1',
        title: 'Travel Lessons',
        sourceDocumentIds: const [],
        isArchived: false,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await versionOne.close();

    final upgraded = await QuizDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    addTearDown(upgraded.close);

    final versionRows = await upgraded.connection.rawQuery(
      'PRAGMA user_version',
    );
    expect(versionRows.single['user_version'], QuizDatabase.schemaVersion);
    final restored = await SqliteKnowledgeBaseRepository(
      upgraded,
    ).getById('knowledge-base-1');
    expect(restored!.title, 'Travel Lessons');

    final indexRows = await upgraded.connection.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    final indexNames = indexRows.map((row) => row['name']).toSet();
    expect(indexNames, contains('idx_knowledge_bases_archive_updated'));
    expect(indexNames, contains('idx_quizzes_knowledge_base'));
    expect(indexNames, contains('idx_attempts_status_completed'));
  });
}
