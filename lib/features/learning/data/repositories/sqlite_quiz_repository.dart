import 'package:sqflite/sqflite.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../local/quiz_database.dart';

class SqliteQuizRepository implements QuizRepository {
  final QuizDatabase database;

  const SqliteQuizRepository(this.database);

  @override
  Future<void> delete(String id) async {
    await database.connection.delete(
      'quizzes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<QuizDefinition>> getAll({bool includeArchived = false}) async {
    final rows = await database.connection.query(
      'quizzes',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'updated_at DESC',
    );
    return Future.wait(rows.map(_quizFromRow));
  }

  @override
  Future<QuizDefinition?> getById(String id) async {
    final rows = await database.connection.query(
      'quizzes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _quizFromRow(rows.single);
  }

  @override
  Future<void> save(QuizDefinition quiz) async {
    await database.connection.transaction((transaction) async {
      final quizValues = <String, Object?>{
        'id': quiz.id,
        'knowledge_base_id': quiz.knowledgeBaseId,
        'title': quiz.title,
        'is_archived': quiz.isArchived ? 1 : 0,
        'created_at': quiz.createdAt.toIso8601String(),
        'updated_at': quiz.updatedAt.toIso8601String(),
      };
      await transaction.insert(
        'quizzes',
        quizValues,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.update(
        'quizzes',
        quizValues,
        where: 'id = ?',
        whereArgs: [quiz.id],
      );

      await transaction.delete(
        'questions',
        where: 'quiz_id = ?',
        whereArgs: [quiz.id],
      );

      for (final indexedQuestion in quiz.questions.indexed) {
        final (questionIndex, question) = indexedQuestion;
        await transaction.insert('questions', {
          'id': question.id,
          'quiz_id': quiz.id,
          'position': questionIndex,
          'prompt': question.prompt,
          'question_type': question.type.name,
          'correct_answer': question.correctAnswer,
        });

        for (final indexedOption in question.options.indexed) {
          final (optionIndex, option) = indexedOption;
          await transaction.insert('answer_options', {
            'question_id': question.id,
            'id': option.id,
            'position': optionIndex,
            'text': option.text,
          });
        }

        final explanation = question.explanation;
        if (explanation != null) {
          await transaction.insert('explanations', {
            'question_id': question.id,
            'text': explanation.text,
            'source_excerpt': explanation.sourceExcerpt,
          });
        }

        for (final indexedConcept in question.concepts.indexed) {
          final (conceptIndex, concept) = indexedConcept;
          await transaction.insert('concepts', {
            'id': concept.id,
            'name': concept.name,
            'category': concept.category,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await transaction.insert('question_concepts', {
            'question_id': question.id,
            'concept_id': concept.id,
            'position': conceptIndex,
          });
        }
      }
    });
  }

  Future<QuizDefinition> _quizFromRow(Map<String, Object?> row) async {
    final questionRows = await database.connection.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [row['id']],
      orderBy: 'position ASC',
    );
    final questions = await Future.wait(questionRows.map(_questionFromRow));
    return QuizDefinition(
      id: row['id']! as String,
      knowledgeBaseId: row['knowledge_base_id'] as String?,
      title: row['title']! as String,
      questions: questions,
      isArchived: (row['is_archived']! as int) == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Future<QuestionDefinition> _questionFromRow(Map<String, Object?> row) async {
    final optionRows = await database.connection.query(
      'answer_options',
      where: 'question_id = ?',
      whereArgs: [row['id']],
      orderBy: 'position ASC',
    );
    final explanationRows = await database.connection.query(
      'explanations',
      where: 'question_id = ?',
      whereArgs: [row['id']],
      limit: 1,
    );
    final conceptRows = await database.connection.rawQuery(
      '''
        SELECT concepts.id, concepts.name, concepts.category
        FROM question_concepts
        INNER JOIN concepts ON concepts.id = question_concepts.concept_id
        WHERE question_concepts.question_id = ?
        ORDER BY question_concepts.position ASC
      ''',
      [row['id']],
    );
    final explanationRow = explanationRows.firstOrNull;
    return QuestionDefinition(
      id: row['id']! as String,
      prompt: row['prompt']! as String,
      type: QuestionType.values.byName(row['question_type']! as String),
      options: optionRows
          .map(
            (option) => AnswerOption(
              id: option['id']! as String,
              text: option['text']! as String,
            ),
          )
          .toList(),
      correctAnswer: row['correct_answer']! as String,
      explanation: explanationRow == null
          ? null
          : QuestionExplanation(
              text: explanationRow['text']! as String,
              sourceExcerpt: explanationRow['source_excerpt'] as String?,
            ),
      concepts: conceptRows
          .map(
            (concept) => Concept(
              id: concept['id']! as String,
              name: concept['name']! as String,
              category: concept['category']! as String,
            ),
          )
          .toList(),
    );
  }
}
