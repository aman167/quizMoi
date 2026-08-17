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
  QuizDefinition? _draftQuiz;
  SourceDocument? _sourceDocument;
  String? _errorCode;
  String? _errorMessage;
  int _idCounter = 0;

  QuizGenerationState get state => _state;
  QuizGenerationRequest? get request => _request;
  QuizDefinition? get draftQuiz => _draftQuiz;
  SourceDocument? get sourceDocument => _sourceDocument;
  String? get errorCode => _errorCode;
  String? get errorMessage => _errorMessage;
  bool get isGenerating => _state == QuizGenerationState.generating;
  bool get canRetry =>
      _request != null && _state == QuizGenerationState.failure;

  bool prepareSource({required String text, required String cefrLevel}) {
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
      sourceTitle: 'Pasted French study text',
      sourceText: trimmed,
      cefrLevel: cefrLevel,
    );
    _state = QuizGenerationState.previewing;
    notifyListeners();
    return true;
  }

  Future<bool> generate() async {
    final generationRequest = _request;
    if (generationRequest == null) {
      _fail('invalid_source', 'Paste and preview study text first.');
      return false;
    }
    _state = QuizGenerationState.generating;
    _clearError();
    notifyListeners();
    try {
      final generated = await gateway.generate(generationRequest);
      final now = _now();
      final sourceId = _newId('source');
      _sourceDocument = SourceDocument(
        id: sourceId,
        title: generationRequest.sourceTitle,
        type: SourceType.pastedText,
        content: generationRequest.sourceText,
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
    _draftQuiz = null;
    _sourceDocument = null;
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
