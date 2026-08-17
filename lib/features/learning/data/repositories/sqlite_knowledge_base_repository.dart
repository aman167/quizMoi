import 'package:sqflite/sqflite.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/knowledge_base_repository.dart';
import '../local/quiz_database.dart';

class SqliteKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final QuizDatabase database;

  const SqliteKnowledgeBaseRepository(this.database);

  @override
  Future<void> delete(String id) async {
    await database.connection.delete(
      'knowledge_bases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<KnowledgeBaseRecord>> getAll({
    bool includeArchived = false,
  }) async {
    final rows = await database.connection.query(
      'knowledge_bases',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'updated_at DESC',
    );
    return Future.wait(rows.map(_knowledgeBaseFromRow));
  }

  @override
  Future<KnowledgeBaseRecord?> getById(String id) async {
    final rows = await database.connection.query(
      'knowledge_bases',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _knowledgeBaseFromRow(rows.single);
  }

  @override
  Future<void> save(KnowledgeBaseRecord knowledgeBase) async {
    await database.connection.transaction((transaction) async {
      final values = <String, Object?>{
        'id': knowledgeBase.id,
        'title': knowledgeBase.title,
        'is_archived': knowledgeBase.isArchived ? 1 : 0,
        'created_at': knowledgeBase.createdAt.toIso8601String(),
        'updated_at': knowledgeBase.updatedAt.toIso8601String(),
      };
      await transaction.insert(
        'knowledge_bases',
        values,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.update(
        'knowledge_bases',
        values,
        where: 'id = ?',
        whereArgs: [knowledgeBase.id],
      );
      await transaction.delete(
        'knowledge_base_sources',
        where: 'knowledge_base_id = ?',
        whereArgs: [knowledgeBase.id],
      );
      for (final sourceDocumentId in knowledgeBase.sourceDocumentIds) {
        await transaction.insert('knowledge_base_sources', {
          'knowledge_base_id': knowledgeBase.id,
          'source_document_id': sourceDocumentId,
        });
      }
    });
  }

  Future<KnowledgeBaseRecord> _knowledgeBaseFromRow(
    Map<String, Object?> row,
  ) async {
    final sourceRows = await database.connection.query(
      'knowledge_base_sources',
      columns: ['source_document_id'],
      where: 'knowledge_base_id = ?',
      whereArgs: [row['id']],
      orderBy: 'source_document_id ASC',
    );
    return KnowledgeBaseRecord(
      id: row['id']! as String,
      title: row['title']! as String,
      sourceDocumentIds: sourceRows
          .map((source) => source['source_document_id']! as String)
          .toList(),
      isArchived: (row['is_archived']! as int) == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
