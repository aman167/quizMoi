import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

class QuizDatabase {
  static const schemaVersion = 4;
  static const databaseName = 'quiz_moi.sqlite';

  final sqflite.Database connection;

  const QuizDatabase._(this.connection);

  static Future<QuizDatabase> open({
    sqflite.DatabaseFactory? factory,
    String? databasePath,
    // Used only by migration tests to create an older schema first.
    int? schemaVersionOverride,
  }) async {
    final selectedFactory = factory ?? sqflite.databaseFactory;
    final selectedPath =
        databasePath ??
        path.join(await selectedFactory.getDatabasesPath(), databaseName);
    final connection = await selectedFactory.openDatabase(
      selectedPath,
      options: sqflite.OpenDatabaseOptions(
        version: schemaVersionOverride ?? schemaVersion,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    return QuizDatabase._(connection);
  }

  Future<void> close() => connection.close();

  static Future<void> _createSchema(
    sqflite.Database database,
    int version,
  ) async {
    final sourceDocumentColumn = version >= 3 ? 'source_document_id TEXT,' : '';
    final sourceUriColumn = version >= 4 ? 'source_uri TEXT,' : '';
    final sourceDocumentForeignKey = version >= 3
        ? ', FOREIGN KEY (source_document_id) REFERENCES source_documents(id) ON DELETE SET NULL'
        : '';
    await database.execute('''
      CREATE TABLE source_documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_type TEXT NOT NULL,
        $sourceUriColumn
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE knowledge_bases (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE knowledge_base_sources (
        knowledge_base_id TEXT NOT NULL,
        source_document_id TEXT NOT NULL,
        PRIMARY KEY (knowledge_base_id, source_document_id),
        FOREIGN KEY (knowledge_base_id) REFERENCES knowledge_bases(id)
          ON DELETE CASCADE,
        FOREIGN KEY (source_document_id) REFERENCES source_documents(id)
          ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE concepts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        knowledge_base_id TEXT,
        $sourceDocumentColumn
        title TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (knowledge_base_id) REFERENCES knowledge_bases(id)
          ON DELETE SET NULL
        $sourceDocumentForeignKey
      )
    ''');
    await database.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        question_type TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE answer_options (
        question_id TEXT NOT NULL,
        id TEXT NOT NULL,
        position INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (question_id, id),
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE explanations (
        question_id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        source_excerpt TEXT,
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE question_concepts (
        question_id TEXT NOT NULL,
        concept_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (question_id, concept_id),
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
        FOREIGN KEY (concept_id) REFERENCES concepts(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        status TEXT NOT NULL,
        current_question_index INTEGER NOT NULL,
        elapsed_seconds INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE question_answers (
        attempt_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        value TEXT NOT NULL,
        answered_at TEXT NOT NULL,
        PRIMARY KEY (attempt_id, question_id),
        FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id) ON DELETE CASCADE,
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE learner_settings (
        id TEXT PRIMARY KEY,
        cefr_level TEXT NOT NULL,
        daily_question_goal INTEGER NOT NULL,
        reminders_enabled INTEGER NOT NULL
      )
    ''');
    if (version >= 2) {
      await _createVersion2Indexes(database);
    }
    if (version >= 3) {
      await _createVersion3Indexes(database);
    }
  }

  static Future<void> _upgradeSchema(
    sqflite.Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await _createSchema(database, newVersion);
      return;
    }
    if (oldVersion < 2) {
      await _createVersion2Indexes(database);
    }
    if (oldVersion < 3) {
      await database.execute('''
        ALTER TABLE quizzes ADD COLUMN source_document_id TEXT
        REFERENCES source_documents(id) ON DELETE SET NULL
      ''');
      await _createVersion3Indexes(database);
    }
    if (oldVersion < 4) {
      await database.execute(
        'ALTER TABLE source_documents ADD COLUMN source_uri TEXT',
      );
    }
  }

  static Future<void> _createVersion2Indexes(sqflite.Database database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_knowledge_bases_archive_updated
      ON knowledge_bases(is_archived, updated_at DESC)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_quizzes_knowledge_base
      ON quizzes(knowledge_base_id)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_attempts_status_completed
      ON quiz_attempts(status, completed_at DESC)
    ''');
  }

  static Future<void> _createVersion3Indexes(sqflite.Database database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_quizzes_source_document
      ON quizzes(source_document_id)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_source_documents_created
      ON source_documents(created_at DESC)
    ''');
  }
}
