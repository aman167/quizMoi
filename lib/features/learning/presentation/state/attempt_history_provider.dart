import 'package:flutter/foundation.dart';

import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../../domain/repositories/quiz_repository.dart';

enum AttemptHistoryLoadState { initial, loading, ready, error }

@immutable
class AttemptHistoryEntry {
  final QuizAttempt attempt;
  final String quizTitle;
  final int correctAnswers;
  final int totalQuestions;

  const AttemptHistoryEntry({
    required this.attempt,
    required this.quizTitle,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  DateTime get completedAt => attempt.completedAt ?? attempt.startedAt;

  double get scorePercent =>
      totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;
}

class AttemptHistoryProvider extends ChangeNotifier {
  final AttemptRepository attemptRepository;
  final QuizRepository quizRepository;
  final DateTime Function() _now;

  AttemptHistoryProvider({
    required this.attemptRepository,
    required this.quizRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  AttemptHistoryLoadState _state = AttemptHistoryLoadState.initial;
  List<AttemptHistoryEntry> _entries = const [];
  Object? _error;

  AttemptHistoryLoadState get state => _state;
  List<AttemptHistoryEntry> get entries => List.unmodifiable(_entries);
  Object? get error => _error;
  bool get isLoading => _state == AttemptHistoryLoadState.loading;
  int get completedAttemptCount => _entries.length;
  int get totalCorrectAnswers =>
      _entries.fold(0, (total, entry) => total + entry.correctAnswers);
  int get totalQuestions =>
      _entries.fold(0, (total, entry) => total + entry.totalQuestions);
  double get accuracyPercent =>
      totalQuestions == 0 ? 0 : (totalCorrectAnswers / totalQuestions) * 100;
  int get questionsCompletedToday {
    final today = _now().toLocal();
    return _entries
        .where((entry) => _isSameDay(entry.completedAt.toLocal(), today))
        .fold(0, (total, entry) => total + entry.totalQuestions);
  }

  Future<void> load() async {
    _state = AttemptHistoryLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final attempts = await attemptRepository.getCompleted();
      final loadedEntries = <AttemptHistoryEntry>[];
      for (final attempt in attempts) {
        final quiz = await quizRepository.getById(attempt.quizId);
        if (quiz == null) continue;

        final answersByQuestion = {
          for (final answer in attempt.answers) answer.questionId: answer.value,
        };
        final correctAnswers = quiz.questions
            .where(
              (question) =>
                  answersByQuestion[question.id] == question.correctAnswer,
            )
            .length;
        loadedEntries.add(
          AttemptHistoryEntry(
            attempt: attempt,
            quizTitle: quiz.title,
            correctAnswers: correctAnswers,
            totalQuestions: quiz.questions.length,
          ),
        );
      }
      _entries = List.unmodifiable(loadedEntries);
      _state = AttemptHistoryLoadState.ready;
    } catch (error) {
      _error = error;
      _state = AttemptHistoryLoadState.error;
    }
    notifyListeners();
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
