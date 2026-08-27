import 'package:flutter/foundation.dart';

import '../../../learning/domain/entities/learning_entities.dart';
import '../../domain/quiz_generation_gateway.dart';
import '../../domain/quiz_generation_models.dart';

enum QuizGenerationState {
  idle,
  validating,
  previewing,
  generating,
  reviewing,
  saving,
  success,
  failure,
}

class QuizGenerationProvider extends ChangeNotifier {
  final QuizGenerationGateway gateway;
  final DateTime Function() _now;

  QuizGenerationProvider({required this.gateway, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  QuizGenerationState _state = QuizGenerationState.idle;
  QuizGenerationRequest? _request;
  PdfQuizGenerationRequest? _pdfRequest;
  QuizDefinition? _draftQuiz;
  SourceDocument? _sourceDocument;
  String? _errorCode;
  String? _errorMessage;
  SourceType _sourceType = SourceType.pastedText;
  int _idCounter = 0;

  QuizGenerationState get state => _state;
  QuizGenerationRequest? get request => _request;
  PdfQuizGenerationRequest? get pdfRequest => _pdfRequest;
  QuizDefinition? get draftQuiz => _draftQuiz;
  SourceDocument? get sourceDocument => _sourceDocument;
  String? get errorCode => _errorCode;
  String? get errorMessage => _errorMessage;
  bool get isGenerating => _state == QuizGenerationState.generating;
  bool get canRetry =>
      (_request != null || _pdfRequest != null) &&
      _state == QuizGenerationState.failure;

  bool prepareSource({
    required String text,
    required String cefrLevel,
    String sourceTitle = 'Pasted French study text',
    SourceType sourceType = SourceType.pastedText,
  }) {
    _state = QuizGenerationState.validating;
    _clearError();
    notifyListeners();

    final trimmed = text.trim();
    if (trimmed.length < 200) {
      _fail(
        'invalid_source',
        'Add at least 200 characters so the AI has enough material for a useful quiz.',
      );
      return false;
    }
    if (trimmed.length > 12000) {
      _fail(
        'invalid_source',
        'This prototype accepts up to 12,000 characters. Shorten the text, then retry.',
      );
      return false;
    }

    _request = QuizGenerationRequest(
      sourceTitle: sourceTitle.trim().isEmpty
          ? 'French study material'
          : sourceTitle.trim(),
      sourceText: trimmed,
      cefrLevel: cefrLevel,
    );
    _pdfRequest = null;
    _sourceType = sourceType;
    _state = QuizGenerationState.previewing;
    notifyListeners();
    return true;
  }

  bool preparePdf({
    required String sourceTitle,
    required String fileName,
    required Uint8List pdfBytes,
    required String cefrLevel,
  }) {
    _state = QuizGenerationState.validating;
    _clearError();
    notifyListeners();

    if (pdfBytes.isEmpty || !fileName.toLowerCase().endsWith('.pdf')) {
      _fail('invalid_source', 'Choose a readable PDF file first.');
      return false;
    }
    if (pdfBytes.length > 10 * 1024 * 1024) {
      _fail(
        'invalid_source',
        'This prototype accepts PDFs up to 10 MB to control generation time and cost.',
      );
      return false;
    }

    _pdfRequest = PdfQuizGenerationRequest(
      sourceTitle: sourceTitle.trim().isEmpty
          ? 'Imported PDF'
          : sourceTitle.trim(),
      fileName: fileName,
      pdfBytes: pdfBytes,
      cefrLevel: cefrLevel,
    );
    _request = null;
    _sourceType = SourceType.pdf;
    _state = QuizGenerationState.previewing;
    notifyListeners();
    return true;
  }

  Future<bool> generate() async {
    final generationRequest = _request;
    final pdfGenerationRequest = _pdfRequest;
    if (generationRequest == null && pdfGenerationRequest == null) {
      _fail('invalid_source', 'Add and preview study material first.');
      return false;
    }
    _state = QuizGenerationState.generating;
    _clearError();
    notifyListeners();
    try {
      final generated = pdfGenerationRequest == null
          ? await gateway.generate(generationRequest!)
          : await gateway.generatePdf(pdfGenerationRequest);
      final now = _now();
      final sourceId = _newId('source');
      final sourceTitle =
          generationRequest?.sourceTitle ?? pdfGenerationRequest!.sourceTitle;
      final sourceContent =
          generationRequest?.sourceText ??
          'PDF source: ${pdfGenerationRequest!.fileName}';
      _sourceDocument = SourceDocument(
        id: sourceId,
        title: sourceTitle,
        type: _sourceType,
        content: sourceContent,
        createdAt: now,
      );
      _draftQuiz = QuizDefinition(
        id: _newId('quiz'),
        sourceDocumentId: sourceId,
        title: generated.title,
        questions: generated.questions.indexed.map((entry) {
          final question = entry.$2;
          return QuestionDefinition(
            id: _newId('question'),
            prompt: question.prompt,
            type: QuestionType.multipleChoice,
            options: question.options,
            correctAnswer: question.correctOptionId,
            explanation: question.explanation,
            concepts: question.concepts.indexed.map((conceptEntry) {
              final concept = conceptEntry.$2;
              return Concept(
                id: _newId('concept'),
                name: concept.name,
                category: concept.category,
              );
            }).toList(),
          );
        }).toList(),
        createdAt: now,
        updatedAt: now,
      );
      _state = QuizGenerationState.reviewing;
      notifyListeners();
      return true;
    } on QuizGenerationException catch (error) {
      _fail(error.code, error.message);
      return false;
    } catch (_) {
      _fail(
        'generation_failed',
        'The quiz could not be generated. Your source text is still available.',
      );
      return false;
    }
  }

  void markSaving() {
    _state = QuizGenerationState.saving;
    _clearError();
    notifyListeners();
  }

  void markSaved() {
    _state = QuizGenerationState.success;
    notifyListeners();
  }

  void reset() {
    _state = QuizGenerationState.idle;
    _request = null;
    _pdfRequest = null;
    _draftQuiz = null;
    _sourceDocument = null;
    _sourceType = SourceType.pastedText;
    _clearError();
    notifyListeners();
  }

  String _newId(String prefix) {
    _idCounter++;
    return '$prefix-${_now().microsecondsSinceEpoch}-$_idCounter';
  }

  void _fail(String code, String message) {
    _state = QuizGenerationState.failure;
    _errorCode = code;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorCode = null;
    _errorMessage = null;
  }
}
