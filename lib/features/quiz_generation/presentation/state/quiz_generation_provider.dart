import 'package:flutter/foundation.dart';

import '../../../learning/domain/entities/learning_entities.dart';
import '../../domain/quiz_generation_gateway.dart';
import '../../domain/quiz_generation_models.dart';

enum QuizGenerationState {
  idle,
  validating,
  fetchingSource,
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
  ImageQuizGenerationRequest? _imageRequest;
  WebArticleSourcePreview? _webArticlePreview;
  QuizDefinition? _draftQuiz;
  SourceDocument? _sourceDocument;
  String? _errorCode;
  String? _errorMessage;
  SourceType _sourceType = SourceType.pastedText;
  int _idCounter = 0;

  QuizGenerationState get state => _state;
  QuizGenerationRequest? get request => _request;
  PdfQuizGenerationRequest? get pdfRequest => _pdfRequest;
  ImageQuizGenerationRequest? get imageRequest => _imageRequest;
  WebArticleSourcePreview? get webArticlePreview => _webArticlePreview;
  QuizDefinition? get draftQuiz => _draftQuiz;
  SourceDocument? get sourceDocument => _sourceDocument;
  String? get errorCode => _errorCode;
  String? get errorMessage => _errorMessage;
  bool get isGenerating => _state == QuizGenerationState.generating;
  bool get isFetchingSource => _state == QuizGenerationState.fetchingSource;
  bool get isBusy =>
      isGenerating || isFetchingSource || _state == QuizGenerationState.saving;
  bool get canRetry =>
      (_request != null || _pdfRequest != null || _imageRequest != null) &&
      _state == QuizGenerationState.failure;

  bool prepareSource({
    required String text,
    required String cefrLevel,
    String sourceTitle = 'Pasted French study text',
    SourceType sourceType = SourceType.pastedText,
    String difficulty = 'medium',
    int questionCount = 10,
    List<QuestionType> questionTypes = const [QuestionType.multipleChoice],
    int? timeLimitMinutes,
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
    if (trimmed.length > 60000) {
      _fail(
        'invalid_source',
        'This prototype accepts up to 60,000 characters. Shorten the text, then retry.',
      );
      return false;
    }

    _request = QuizGenerationRequest(
      requestId: _newId('generation'),
      sourceTitle: sourceTitle.trim().isEmpty
          ? 'French study material'
          : sourceTitle.trim(),
      sourceText: trimmed,
      cefrLevel: cefrLevel,
      difficulty: difficulty,
      questionCount: questionCount,
      questionTypes: questionTypes,
      timeLimitMinutes: timeLimitMinutes,
    );
    _pdfRequest = null;
    _imageRequest = null;
    _webArticlePreview = null;
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
    String difficulty = 'medium',
    int questionCount = 10,
    List<QuestionType> questionTypes = const [QuestionType.multipleChoice],
    int? timeLimitMinutes,
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
      requestId: _newId('generation'),
      sourceTitle: sourceTitle.trim().isEmpty
          ? 'Imported PDF'
          : sourceTitle.trim(),
      fileName: fileName,
      pdfBytes: pdfBytes,
      cefrLevel: cefrLevel,
      difficulty: difficulty,
      questionCount: questionCount,
      questionTypes: questionTypes,
      timeLimitMinutes: timeLimitMinutes,
    );
    _request = null;
    _imageRequest = null;
    _webArticlePreview = null;
    _sourceType = SourceType.pdf;
    _state = QuizGenerationState.previewing;
    notifyListeners();
    return true;
  }

  bool prepareImage({
    required String sourceTitle,
    required String fileName,
    required String mimeType,
    required Uint8List imageBytes,
    required String cefrLevel,
    String difficulty = 'medium',
    int questionCount = 10,
    List<QuestionType> questionTypes = const [QuestionType.multipleChoice],
    int? timeLimitMinutes,
  }) {
    _state = QuizGenerationState.validating;
    _clearError();
    notifyListeners();
    if (imageBytes.isEmpty ||
        !const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      _fail(
        'invalid_source',
        'Capture a readable JPEG, PNG, or WebP image first.',
      );
      return false;
    }
    if (imageBytes.length > 10 * 1024 * 1024) {
      _fail('invalid_source', 'This prototype accepts images up to 10 MB.');
      return false;
    }
    _imageRequest = ImageQuizGenerationRequest(
      requestId: _newId('generation'),
      sourceTitle: sourceTitle.trim().isEmpty
          ? 'Camera study image'
          : sourceTitle.trim(),
      fileName: fileName,
      mimeType: mimeType,
      imageBytes: imageBytes,
      cefrLevel: cefrLevel,
      difficulty: difficulty,
      questionCount: questionCount,
      questionTypes: questionTypes,
      timeLimitMinutes: timeLimitMinutes,
    );
    _request = null;
    _pdfRequest = null;
    _webArticlePreview = null;
    _sourceType = SourceType.image;
    _state = QuizGenerationState.previewing;
    notifyListeners();
    return true;
  }

  Future<bool> prepareWebArticle({
    required String url,
    required String cefrLevel,
    String difficulty = 'medium',
    int questionCount = 10,
    List<QuestionType> questionTypes = const [QuestionType.multipleChoice],
    int? timeLimitMinutes,
  }) async {
    _state = QuizGenerationState.validating;
    _clearError();
    notifyListeners();

    final trimmed = url.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null ||
        !{'http', 'https'}.contains(parsed.scheme.toLowerCase()) ||
        parsed.host.isEmpty) {
      _fail(
        'invalid_url',
        'Enter a complete http:// or https:// web article URL.',
      );
      return false;
    }

    _state = QuizGenerationState.fetchingSource;
    notifyListeners();
    try {
      final preview = await gateway.previewWebArticle(trimmed);
      _webArticlePreview = preview;
      _request = QuizGenerationRequest(
        requestId: _newId('generation'),
        sourceTitle: preview.title,
        sourceText: preview.text,
        cefrLevel: cefrLevel,
        difficulty: difficulty,
        questionCount: questionCount,
        questionTypes: questionTypes,
        timeLimitMinutes: timeLimitMinutes,
      );
      _pdfRequest = null;
      _imageRequest = null;
      _sourceType = SourceType.webArticle;
      _state = QuizGenerationState.previewing;
      notifyListeners();
      return true;
    } on QuizGenerationException catch (error) {
      _fail(error.code, error.message);
      return false;
    } catch (_) {
      _fail(
        'article_unavailable',
        'The article could not be retrieved. Your URL is still available.',
      );
      return false;
    }
  }

  Future<bool> generate() async {
    final generationRequest = _request;
    final pdfGenerationRequest = _pdfRequest;
    final imageGenerationRequest = _imageRequest;
    if (generationRequest == null &&
        pdfGenerationRequest == null &&
        imageGenerationRequest == null) {
      _fail('invalid_source', 'Add and preview study material first.');
      return false;
    }
    _state = QuizGenerationState.generating;
    _clearError();
    notifyListeners();
    try {
      final GeneratedQuizDraft generated;
      if (pdfGenerationRequest != null) {
        generated = await gateway.generatePdf(pdfGenerationRequest);
      } else if (imageGenerationRequest != null) {
        generated = await gateway.generateImage(imageGenerationRequest);
      } else {
        generated = await gateway.generate(generationRequest!);
      }
      final now = _now();
      final sourceId = _newId('source');
      final sourceTitle =
          generationRequest?.sourceTitle ??
          pdfGenerationRequest?.sourceTitle ??
          imageGenerationRequest!.sourceTitle;
      final sourceContent =
          generationRequest?.sourceText ??
          (pdfGenerationRequest != null
              ? 'PDF source: ${pdfGenerationRequest.fileName}'
              : 'Camera image: ${imageGenerationRequest!.fileName}');
      _sourceDocument = SourceDocument(
        id: sourceId,
        title: sourceTitle,
        type: _sourceType,
        content: sourceContent,
        sourceUri: _webArticlePreview?.url,
        createdAt: now,
      );
      _draftQuiz = QuizDefinition(
        id: _newId('quiz'),
        sourceDocumentId: sourceId,
        title: generated.title,
        questions: generated.questions
            .map((question) => _toQuestionDefinition(question))
            .toList(),
        createdAt: now,
        updatedAt: now,
        timeLimitMinutes:
            generationRequest?.timeLimitMinutes ??
            pdfGenerationRequest?.timeLimitMinutes ??
            imageGenerationRequest?.timeLimitMinutes,
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

  Future<bool> regenerateQuestion(int index) async {
    final draft = _draftQuiz;
    if (draft == null || index < 0 || index >= draft.questions.length) {
      return false;
    }
    _state = QuizGenerationState.generating;
    _clearError();
    notifyListeners();
    try {
      final requestId = _newId('generation');
      final GeneratedQuizDraft generated;
      if (_pdfRequest != null) {
        final source = _pdfRequest!;
        generated = await gateway.generatePdf(
          PdfQuizGenerationRequest(
            requestId: requestId,
            sourceTitle: source.sourceTitle,
            fileName: source.fileName,
            pdfBytes: source.pdfBytes,
            cefrLevel: source.cefrLevel,
            difficulty: source.difficulty,
            questionCount: 1,
            questionTypes: [draft.questions[index].type],
            timeLimitMinutes: source.timeLimitMinutes,
          ),
        );
      } else if (_imageRequest != null) {
        final source = _imageRequest!;
        generated = await gateway.generateImage(
          ImageQuizGenerationRequest(
            requestId: requestId,
            sourceTitle: source.sourceTitle,
            fileName: source.fileName,
            mimeType: source.mimeType,
            imageBytes: source.imageBytes,
            cefrLevel: source.cefrLevel,
            difficulty: source.difficulty,
            questionCount: 1,
            questionTypes: [draft.questions[index].type],
            timeLimitMinutes: source.timeLimitMinutes,
          ),
        );
      } else {
        generated = await gateway.generate(
          _request!.copyWith(
            requestId: requestId,
            questionCount: 1,
            questionTypes: [draft.questions[index].type],
          ),
        );
      }
      final questions = draft.questions.toList();
      questions[index] = _toQuestionDefinition(
        generated.questions.single,
        id: questions[index].id,
      );
      _draftQuiz = draft.copyWith(questions: questions, updatedAt: _now());
      _state = QuizGenerationState.reviewing;
      notifyListeners();
      return true;
    } on QuizGenerationException catch (error) {
      _fail(error.code, error.message);
      return false;
    } catch (_) {
      _fail('generation_failed', 'This question could not be regenerated.');
      return false;
    }
  }

  QuestionDefinition _toQuestionDefinition(
    GeneratedQuestionDraft question, {
    String? id,
  }) {
    return QuestionDefinition(
      id: id ?? _newId('question'),
      prompt: question.prompt,
      type: question.type,
      options: question.options,
      correctAnswer: question.correctAnswer,
      acceptedAnswers: question.acceptedAnswers,
      explanation: question.explanation,
      concepts: question.concepts.map((concept) {
        return Concept(
          id: _newId('concept'),
          name: concept.name,
          category: concept.category,
        );
      }).toList(),
    );
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

  void markSaveFailed() {
    _fail(
      'save_failed',
      'The generated quiz could not be saved. Your quiz is still available.',
    );
  }

  void reset() {
    _state = QuizGenerationState.idle;
    _request = null;
    _pdfRequest = null;
    _imageRequest = null;
    _webArticlePreview = null;
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
