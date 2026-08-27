import '../../learning/domain/entities/learning_entities.dart';
import 'dart:typed_data';

class QuizGenerationRequest {
  final int schemaVersion;
  final String requestId;
  final String sourceTitle;
  final String sourceText;
  final String cefrLevel;
  final String difficulty;
  final int questionCount;
  final List<QuestionType> questionTypes;
  final int? timeLimitMinutes;

  const QuizGenerationRequest({
    this.schemaVersion = 1,
    required this.requestId,
    required this.sourceTitle,
    required this.sourceText,
    required this.cefrLevel,
    this.difficulty = 'medium',
    this.questionCount = 10,
    this.questionTypes = const [QuestionType.multipleChoice],
    this.timeLimitMinutes,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'requestId': requestId,
    'sourceTitle': sourceTitle,
    'sourceText': sourceText,
    'cefrLevel': cefrLevel,
    'difficulty': difficulty,
    'questionCount': questionCount,
    'questionTypes': questionTypes.map((type) => type.name).toList(),
  };

  QuizGenerationRequest copyWith({
    String? requestId,
    int? questionCount,
    List<QuestionType>? questionTypes,
  }) => QuizGenerationRequest(
    schemaVersion: schemaVersion,
    requestId: requestId ?? this.requestId,
    sourceTitle: sourceTitle,
    sourceText: sourceText,
    cefrLevel: cefrLevel,
    difficulty: difficulty,
    questionCount: questionCount ?? this.questionCount,
    questionTypes: questionTypes ?? this.questionTypes,
    timeLimitMinutes: timeLimitMinutes,
  );
}

class PdfQuizGenerationRequest {
  final int schemaVersion;
  final String requestId;
  final String sourceTitle;
  final String fileName;
  final Uint8List pdfBytes;
  final String cefrLevel;
  final String difficulty;
  final int questionCount;
  final List<QuestionType> questionTypes;
  final int? timeLimitMinutes;

  const PdfQuizGenerationRequest({
    this.schemaVersion = 1,
    required this.requestId,
    required this.sourceTitle,
    required this.fileName,
    required this.pdfBytes,
    required this.cefrLevel,
    this.difficulty = 'medium',
    this.questionCount = 10,
    this.questionTypes = const [QuestionType.multipleChoice],
    this.timeLimitMinutes,
  });
}

class ImageQuizGenerationRequest {
  final int schemaVersion;
  final String requestId;
  final String sourceTitle;
  final String fileName;
  final String mimeType;
  final Uint8List imageBytes;
  final String cefrLevel;
  final String difficulty;
  final int questionCount;
  final List<QuestionType> questionTypes;
  final int? timeLimitMinutes;

  const ImageQuizGenerationRequest({
    this.schemaVersion = 1,
    required this.requestId,
    required this.sourceTitle,
    required this.fileName,
    required this.mimeType,
    required this.imageBytes,
    required this.cefrLevel,
    this.difficulty = 'medium',
    this.questionCount = 10,
    this.questionTypes = const [QuestionType.multipleChoice],
    this.timeLimitMinutes,
  });
}

class WebArticleSourcePreview {
  final int schemaVersion;
  final String url;
  final String title;
  final String text;
  final int characterCount;
  final bool wasTruncated;

  const WebArticleSourcePreview({
    required this.schemaVersion,
    required this.url,
    required this.title,
    required this.text,
    required this.characterCount,
    required this.wasTruncated,
  });
}

class GeneratedQuestionDraft {
  final String prompt;
  final QuestionType type;
  final List<AnswerOption> options;
  final String correctAnswer;
  final List<String> acceptedAnswers;
  final QuestionExplanation explanation;
  final List<Concept> concepts;

  GeneratedQuestionDraft({
    required this.prompt,
    this.type = QuestionType.multipleChoice,
    required List<AnswerOption> options,
    required this.correctAnswer,
    List<String> acceptedAnswers = const [],
    required this.explanation,
    required List<Concept> concepts,
  }) : options = List.unmodifiable(options),
       acceptedAnswers = List.unmodifiable(acceptedAnswers),
       concepts = List.unmodifiable(concepts);

  String get correctOptionId => correctAnswer;
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
