import 'dart:async';

import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../features/learning/domain/entities/learning_entities.dart'
    as learning;
import '../features/learning/domain/repositories/attempt_repository.dart';
import '../features/learning/domain/repositories/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  final AttemptRepository? attemptRepository;
  final Future<void> Function()? onAttemptCompleted;
  final DateTime Function() _now;

  QuizProvider({
    this.attemptRepository,
    this.onAttemptCompleted,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Quiz? _currentQuiz;
  int _currentQuestionIndex = 0;
  int _elapsedSeconds = 0;
  bool _quizCompleted = false;
  learning.QuizDefinition? _savedQuizDefinition;
  String? _activeAttemptId;
  DateTime? _attemptStartedAt;
  final Map<String, DateTime> _answerTimes = {};
  Future<void> _writeQueue = Future.value();
  int _attemptCounter = 0;
  bool _completionReported = false;

  Quiz? get currentQuiz => _currentQuiz;
  learning.QuizDefinition? get savedQuizDefinition => _savedQuizDefinition;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get elapsedSeconds => _elapsedSeconds;
  bool get quizCompleted => _quizCompleted;
  bool get canAdvance => currentQuestion?.isAnswered ?? false;
  int? get timeLimitSeconds => _savedQuizDefinition?.timeLimitMinutes == null
      ? null
      : _savedQuizDefinition!.timeLimitMinutes! * 60;
  int? get remainingSeconds => timeLimitSeconds == null
      ? null
      : (timeLimitSeconds! - _elapsedSeconds).clamp(0, timeLimitSeconds!);
  bool get hasResumableSession =>
      _savedQuizDefinition != null &&
      _activeAttemptId != null &&
      _currentQuiz != null &&
      !_quizCompleted;

  learning.QuestionDefinition? savedQuestionForNumber(int questionNumber) {
    final savedQuiz = _savedQuizDefinition;
    final index = questionNumber - 1;
    if (savedQuiz == null || index < 0 || index >= savedQuiz.questions.length) {
      return null;
    }
    return savedQuiz.questions[index];
  }

  QuizQuestion? get currentQuestion {
    if (_currentQuiz == null ||
        _currentQuestionIndex >= _currentQuiz!.questions.length) {
      return null;
    }
    return _currentQuiz!.questions[_currentQuestionIndex];
  }

  double get progress {
    if (_currentQuiz == null || _currentQuiz!.questions.isEmpty) return 0.0;
    return (_currentQuestionIndex + 1) / _currentQuiz!.questions.length;
  }

  String get formattedTime {
    final mins = _elapsedSeconds ~/ 60;
    final secs = _elapsedSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  void startQuiz(String knowledgeBaseId) {
    _clearPersistenceState();
    final questions = [
      QuizQuestion(
        number: 1,
        prompt: 'Quel est le synonyme de "quotidien" ?',
        options: [
          QuizOption(id: 'a', text: 'Rare'),
          QuizOption(id: 'b', text: 'Journalier'),
          QuizOption(id: 'c', text: 'Ancien'),
          QuizOption(id: 'd', text: 'Nouveau'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 2,
        prompt: 'Comment dit-on "to remember" en français ?',
        options: [
          QuizOption(id: 'a', text: 'Oublier'),
          QuizOption(id: 'b', text: 'Se souvenir'),
          QuizOption(id: 'c', text: 'Perdre'),
          QuizOption(id: 'd', text: 'Chercher'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 3,
        prompt: 'Complétez : "Il fait ___ aujourd\'hui." (It\'s nice weather)',
        options: [
          QuizOption(id: 'a', text: 'froid'),
          QuizOption(id: 'b', text: 'beau'),
          QuizOption(id: 'c', text: 'nuit'),
          QuizOption(id: 'd', text: 'mal'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 4,
        prompt:
            'Dans le contexte de l\'article sur le changement climatique, que signifie l\'expression "passer au crible" ?',
        options: [
          QuizOption(id: 'a', text: 'Ignorer complètement un problème.'),
          QuizOption(id: 'b', text: 'Examiner minutieusement et en détail.'),
          QuizOption(id: 'c', text: 'Transmettre une information rapidement.'),
          QuizOption(id: 'd', text: 'Trier des déchets recyclables.'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 5,
        prompt: 'Quel est le passé composé de "aller" avec "je" ?',
        options: [
          QuizOption(id: 'a', text: 'J\'ai allé'),
          QuizOption(id: 'b', text: 'Je suis allé'),
          QuizOption(id: 'c', text: 'J\'allais'),
          QuizOption(id: 'd', text: 'Je vais'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 6,
        prompt: 'Que signifie "néanmoins" ?',
        options: [
          QuizOption(id: 'a', text: 'Jamais'),
          QuizOption(id: 'b', text: 'Toujours'),
          QuizOption(id: 'c', text: 'Cependant'),
          QuizOption(id: 'd', text: 'Ensuite'),
        ],
        correctOptionId: 'c',
      ),
      QuizQuestion(
        number: 7,
        prompt: 'Complétez : "Elle ___ (se lever) tôt chaque matin."',
        options: [
          QuizOption(id: 'a', text: 'se lève'),
          QuizOption(id: 'b', text: 'se lever'),
          QuizOption(id: 'c', text: 'lève'),
          QuizOption(id: 'd', text: 'se levons'),
        ],
        correctOptionId: 'a',
      ),
      QuizQuestion(
        number: 8,
        prompt: 'Comment dit-on "environment" en français ?',
        options: [
          QuizOption(id: 'a', text: 'L\'environnement'),
          QuizOption(id: 'b', text: 'L\'entourage'),
          QuizOption(id: 'c', text: 'L\'enveloppe'),
          QuizOption(id: 'd', text: 'L\'envoi'),
        ],
        correctOptionId: 'a',
      ),
      QuizQuestion(
        number: 9,
        prompt: 'Quel mot signifie "however" en français ?',
        options: [
          QuizOption(id: 'a', text: 'Pourtant'),
          QuizOption(id: 'b', text: 'Parce que'),
          QuizOption(id: 'c', text: 'Puis'),
          QuizOption(id: 'd', text: 'Pour'),
        ],
        correctOptionId: 'a',
      ),
      QuizQuestion(
        number: 10,
        prompt: 'Complétez : "Nous ___ (devoir) étudier pour l\'examen."',
        options: [
          QuizOption(id: 'a', text: 'devions'),
          QuizOption(id: 'b', text: 'devons'),
          QuizOption(id: 'c', text: 'doivent'),
          QuizOption(id: 'd', text: 'dois'),
        ],
        correctOptionId: 'b',
      ),
    ];

    _currentQuiz = Quiz(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Advanced French Vocabulary',
      source: 'Le Monde Articles (Unit 4)',
      questions: questions,
    );

    _currentQuestionIndex = 0;
    _elapsedSeconds = 0;
    _quizCompleted = false;
    notifyListeners();
  }

  void startSavedQuiz(learning.QuizDefinition savedQuiz) {
    _loadSavedQuiz(savedQuiz);
    final now = _now();
    _attemptCounter++;
    _activeAttemptId = 'attempt-${now.microsecondsSinceEpoch}-$_attemptCounter';
    _attemptStartedAt = now;
    _answerTimes.clear();
    unawaited(persistSession().catchError((_) {}));
    notifyListeners();
  }

  void _loadSavedQuiz(learning.QuizDefinition savedQuiz) {
    _savedQuizDefinition = savedQuiz;
    _currentQuiz = Quiz(
      id: savedQuiz.id,
      title: savedQuiz.title,
      source: savedQuiz.sourceDocumentId == null
          ? 'Saved manual quiz'
          : 'Generated from saved study text',
      questions: savedQuiz.questions.indexed.map((entry) {
        final (index, question) = entry;
        return QuizQuestion(
          number: index + 1,
          prompt: question.prompt,
          options: question.options
              .map((option) => QuizOption(id: option.id, text: option.text))
              .toList(),
          correctOptionId: question.correctAnswer,
          acceptedAnswers: question.acceptedAnswers,
          type: question.type.name,
        );
      }).toList(),
    );
    _currentQuestionIndex = 0;
    _elapsedSeconds = 0;
    _quizCompleted = false;
    _completionReported = false;
  }

  void selectOption(String optionId) {
    if (_currentQuiz == null || _quizCompleted) return;
    _currentQuiz!.questions[_currentQuestionIndex].selectedOptionId = optionId;
    final savedQuiz = _savedQuizDefinition;
    if (savedQuiz != null) {
      _answerTimes[savedQuiz.questions[_currentQuestionIndex].id] = _now();
      unawaited(persistSession().catchError((_) {}));
    }
    notifyListeners();
  }

  void enterTypedAnswer(String value) => selectOption(value);

  bool nextQuestion() {
    if (_currentQuiz == null || !canAdvance || _quizCompleted) return false;
    if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _quizCompleted = true;
    }
    unawaited(persistSession().catchError((_) {}));
    notifyListeners();
    return true;
  }

  bool skipQuestion() {
    if (_currentQuiz == null || _quizCompleted) return false;
    if (_currentQuestionIndex >= _currentQuiz!.questions.length - 1) {
      return false;
    }
    _currentQuestionIndex++;
    unawaited(persistSession().catchError((_) {}));
    notifyListeners();
    return true;
  }

  void goToQuestion(int index) {
    final quiz = _currentQuiz;
    if (quiz == null ||
        _quizCompleted ||
        index < 0 ||
        index >= quiz.questions.length) {
      return;
    }
    _currentQuestionIndex = index;
    unawaited(persistSession().catchError((_) {}));
    notifyListeners();
  }

  bool completeQuiz() {
    if (_currentQuiz == null || _quizCompleted) return false;
    _quizCompleted = true;
    unawaited(persistSession().catchError((_) {}));
    notifyListeners();
    return true;
  }

  Future<void> pauseQuiz() => persistSession();

  void previousQuestion() {
    if (_currentQuiz == null) return;
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      unawaited(persistSession().catchError((_) {}));
      notifyListeners();
    }
  }

  void resetQuiz() {
    _currentQuiz = null;
    _currentQuestionIndex = 0;
    _elapsedSeconds = 0;
    _quizCompleted = false;
    _clearPersistenceState();
    notifyListeners();
  }

  Future<void> persistSession() {
    final repository = attemptRepository;
    final savedQuiz = _savedQuizDefinition;
    final attemptId = _activeAttemptId;
    final startedAt = _attemptStartedAt;
    if (repository == null ||
        savedQuiz == null ||
        attemptId == null ||
        startedAt == null ||
        _currentQuiz == null) {
      return Future.value();
    }

    final now = _now();
    final answers = <learning.QuestionAnswer>[];
    for (final indexedQuestion in _currentQuiz!.questions.indexed) {
      final (index, question) = indexedQuestion;
      final selectedOptionId = question.selectedOptionId;
      if (selectedOptionId == null) continue;
      final questionId = savedQuiz.questions[index].id;
      answers.add(
        learning.QuestionAnswer(
          questionId: questionId,
          value: selectedOptionId,
          answeredAt: _answerTimes[questionId] ?? now,
        ),
      );
    }
    final attempt = learning.QuizAttempt(
      id: attemptId,
      quizId: savedQuiz.id,
      status: _quizCompleted
          ? learning.AttemptStatus.completed
          : learning.AttemptStatus.inProgress,
      answers: answers,
      currentQuestionIndex: _currentQuestionIndex,
      elapsedSeconds: _elapsedSeconds,
      startedAt: startedAt,
      completedAt: _quizCompleted ? now : null,
    );
    _writeQueue = _writeQueue.catchError((_) {}).then((_) async {
      await repository.save(attempt);
      if (attempt.status == learning.AttemptStatus.completed &&
          !_completionReported) {
        _completionReported = true;
        await onAttemptCompleted?.call();
      }
    });
    return _writeQueue;
  }

  Future<bool> restoreInProgress(QuizRepository quizRepository) async {
    final repository = attemptRepository;
    if (repository == null) return false;
    final attempt = await repository.getLatestInProgress();
    if (attempt == null) return false;
    final quiz = await quizRepository.getById(attempt.quizId);
    if (quiz == null) {
      await repository.delete(attempt.id);
      return false;
    }

    _loadSavedQuiz(quiz);
    _activeAttemptId = attempt.id;
    _attemptStartedAt = attempt.startedAt;
    _elapsedSeconds = attempt.elapsedSeconds;
    _answerTimes.clear();
    _currentQuestionIndex = attempt.currentQuestionIndex
        .clamp(0, quiz.questions.length - 1)
        .toInt();
    final answersByQuestion = {
      for (final answer in attempt.answers) answer.questionId: answer,
    };
    for (final indexedQuestion in quiz.questions.indexed) {
      final (index, question) = indexedQuestion;
      final answer = answersByQuestion[question.id];
      if (answer == null) continue;
      _currentQuiz!.questions[index].selectedOptionId = answer.value;
      _answerTimes[question.id] = answer.answeredAt;
    }
    notifyListeners();
    return true;
  }

  Future<void> abandonQuiz() async {
    final attemptId = _activeAttemptId;
    final repository = attemptRepository;
    await _writeQueue.catchError((_) {});
    if (attemptId != null && repository != null) {
      await repository.delete(attemptId);
    }
    resetQuiz();
  }

  Future<void> restartCurrentQuiz() async {
    final savedQuiz = _savedQuizDefinition;
    final attemptId = _activeAttemptId;
    final repository = attemptRepository;
    await _writeQueue.catchError((_) {});
    if (attemptId != null && repository != null && !_quizCompleted) {
      await repository.delete(attemptId);
    }
    if (savedQuiz == null) {
      startQuiz('restart');
    } else {
      startSavedQuiz(savedQuiz);
    }
  }

  void retakeCurrentQuiz() {
    final savedQuiz = _savedQuizDefinition;
    if (savedQuiz == null) {
      startQuiz('retake');
    } else {
      startSavedQuiz(savedQuiz);
    }
  }

  void _clearPersistenceState() {
    _savedQuizDefinition = null;
    _activeAttemptId = null;
    _attemptStartedAt = null;
    _answerTimes.clear();
    _completionReported = false;
  }

  bool incrementTimer() {
    if (_currentQuiz == null || _quizCompleted) return false;
    _elapsedSeconds++;
    final expired =
        timeLimitSeconds != null && _elapsedSeconds >= timeLimitSeconds!;
    if (expired) {
      _quizCompleted = true;
      unawaited(persistSession().catchError((_) {}));
    }
    notifyListeners();
    return expired;
  }
}
