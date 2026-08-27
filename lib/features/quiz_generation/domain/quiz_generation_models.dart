import '../../learning/domain/entities/learning_entities.dart';
import 'dart:typed_data';

class QuizGenerationRequest {
  final int schemaVersion;
  final String sourceTitle;
  final String sourceText;
  final String cefrLevel;
  final String difficulty;
  final int questionCount;

  const QuizGenerationRequest({
    this.schemaVersion = 1,
    required this.sourceTitle,
    required this.sourceText,
    required this.cefrLevel,
    this.difficulty = 'medium',
    this.questionCount = 10,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'sourceTitle': sourceTitle,
    'sourceText': sourceText,
    'cefrLevel': cefrLevel,
    'difficulty': difficulty,
    'questionCount': questionCount,
    'questionTypes': const ['multipleChoice'],
  };
}

class PdfQuizGenerationRequest {
  final int schemaVersion;
  final String sourceTitle;
  final String fileName;
  final Uint8List pdfBytes;
  final String cefrLevel;
  final String difficulty;
  final int questionCount;

  const PdfQuizGenerationRequest({
    this.schemaVersion = 1,
    required this.sourceTitle,
    required this.fileName,
    required this.pdfBytes,
    required this.cefrLevel,
    this.difficulty = 'medium',
    this.questionCount = 10,
  });
}

class GeneratedQuestionDraft {
  final String prompt;
  final List<AnswerOption> options;
  final String correctOptionId;
  final QuestionExplanation explanation;
  final List<Concept> concepts;

  GeneratedQuestionDraft({
    required this.prompt,
    required List<AnswerOption> options,
    required this.correctOptionId,
    required this.explanation,
    required List<Concept> concepts,
  }) : options = List.unmodifiable(options),
       concepts = List.unmodifiable(concepts);
}

class GeneratedQuizDraft {
  final int schemaVersion;
  final String requestId;
  final String title;
  final List<GeneratedQuestionDraft> questions;

  GeneratedQuizDraft({
    required this.schemaVersion,
    required this.requestId,
    required this.title,
    required List<GeneratedQuestionDraft> questions,
  }) : questions = List.unmodifiable(questions);
}

class QuizGenerationException implements Exception {
  final String code;
  final String message;

  const QuizGenerationException(this.code, this.message);

  @override
  String toString() => message;
}
