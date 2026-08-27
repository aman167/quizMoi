import 'package:sqflite/sqflite.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/source_document_repository.dart';
import '../local/quiz_database.dart';

class SqliteSourceDocumentRepository implements SourceDocumentRepository {
  final QuizDatabase database;

  const SqliteSourceDocumentRepository(this.database);

  @override
  Future<void> delete(String id) async {
    await database.connection.delete(
      'source_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<SourceDocument>> getAll() async {
    final rows = await database.connection.query(
      'source_documents',
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SourceDocument?> getById(String id) async {
    final rows = await database.connection.query(
      'source_documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<SourceDocument?> findDuplicate(SourceDocument source) async {
    final sources = await getAll();
    for (final candidate in sources) {
      if (candidate.id != source.id && _sameSource(candidate, source)) {
        return candidate;
      }
    }
    return null;
  }

  @override
  Future<void> save(SourceDocument source) async {
    await database.connection.insert('source_documents', {
      'id': source.id,
      'title': source.title,
      'source_type': source.type.name,
      'source_uri': source.sourceUri,
      'content': source.content,
      'created_at': source.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  SourceDocument _fromRow(Map<String, Object?> row) => SourceDocument(
    id: row['id']! as String,
    title: row['title']! as String,
    type: SourceType.values.byName(row['source_type']! as String),
    sourceUri: row['source_uri'] as String?,
    content: row['content']! as String,
    createdAt: DateTime.parse(row['created_at']! as String),
  );
}

bool _sameSource(SourceDocument left, SourceDocument right) {
  if (left.type != right.type) return false;
  if (left.sourceUri != null && right.sourceUri != null) {
    return left.sourceUri!.trim().toLowerCase() ==
        right.sourceUri!.trim().toLowerCase();
  }
  String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return normalize(left.content) == normalize(right.content);
}
