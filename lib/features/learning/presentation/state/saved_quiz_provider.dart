import 'package:flutter/foundation.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/quiz_repository.dart';

enum SavedQuizLoadState { initial, loading, ready, error }

class SavedQuizProvider extends ChangeNotifier {
  final QuizRepository repository;
  final DateTime Function() _now;

  List<QuizDefinition> _quizzes = const [];
  SavedQuizLoadState _loadState = SavedQuizLoadState.initial;
  String? _errorMessage;
  int _idCounter = 0;
  bool _showArchived = false;

  SavedQuizProvider(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  List<QuizDefinition> get quizzes => List.unmodifiable(_quizzes);
  SavedQuizLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadState == SavedQuizLoadState.loading;
  bool get showArchived => _showArchived;

  Future<void> load() async {
    _loadState = SavedQuizLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _quizzes = await repository.getAll(includeArchived: _showArchived);
      _loadState = SavedQuizLoadState.ready;
    } catch (error) {
      _loadState = SavedQuizLoadState.error;
      _errorMessage = 'Saved quizzes could not be loaded.';
    }
    notifyListeners();
  }

  Future<bool> save(QuizDefinition quiz) async {
    try {
      await repository.save(quiz);
      await load();
      return true;
    } catch (error) {
      _loadState = SavedQuizLoadState.error;
      _errorMessage = 'The quiz could not be saved.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteQuiz(String id) async {
    try {
      await repository.delete(id);
      await load();
      return true;
    } catch (error) {
      _errorMessage = 'The quiz could not be deleted.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setArchived(QuizDefinition quiz, bool isArchived) {
    return save(quiz.copyWith(isArchived: isArchived, updatedAt: _now()));
  }

  Future<void> setShowArchived(bool value) async {
    if (_showArchived == value) return;
    _showArchived = value;
    await load();
  }

  Future<bool> duplicate(QuizDefinition quiz) {
    final now = _now();
    final quizId = newId('quiz');
    final duplicate = QuizDefinition(
      id: quizId,
      knowledgeBaseId: quiz.knowledgeBaseId,
      sourceDocumentId: quiz.sourceDocumentId,
      title: '${quiz.title} (Copy)',
      questions: quiz.questions
          .map(
            (question) => QuestionDefinition(
              id: newId('question'),
              prompt: question.prompt,
              type: question.type,
              options: question.options
                  .map(
                    (option) => AnswerOption(id: option.id, text: option.text),
                  )
                  .toList(),
              correctAnswer: question.correctAnswer,
              explanation: question.explanation,
              concepts: question.concepts,
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
    return save(duplicate);
  }

  String newId(String prefix) {
    _idCounter++;
    return '$prefix-${_now().microsecondsSinceEpoch}-$_idCounter';
  }
}
