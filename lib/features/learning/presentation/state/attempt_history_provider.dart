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

enum MasteryStatus { needsReview, learning, mastered }

@immutable
class ConceptMastery {
  final Concept concept;
  final int correctAnswers;
  final int attempts;
  final DateTime? lastIncorrectAt;

  const ConceptMastery({
    required this.concept,
    required this.correctAnswers,
    required this.attempts,
    required this.lastIncorrectAt,
  });

  double get accuracy => attempts == 0 ? 0 : correctAnswers / attempts;
  MasteryStatus get status => attempts >= 3 && accuracy >= 0.8
      ? MasteryStatus.mastered
      : accuracy >= 0.5
      ? MasteryStatus.learning
      : MasteryStatus.needsReview;
}

@immutable
class ReviewRecommendation {
  final ConceptMastery mastery;
  final String quizId;
  final String quizTitle;

  const ReviewRecommendation({
    required this.mastery,
    required this.quizId,
    required this.quizTitle,
  });

  String get reason => mastery.attempts == 1
      ? 'Recommended because your latest answer for this concept was incorrect.'
      : 'Recommended after ${mastery.attempts} answers with ${(mastery.accuracy * 100).round()}% accuracy.';
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
  List<ConceptMastery> _conceptMastery = const [];
  List<ReviewRecommendation> _dailyReviewQueue = const [];
  Object? _error;

  AttemptHistoryLoadState get state => _state;
  List<AttemptHistoryEntry> get entries => List.unmodifiable(_entries);
  List<ConceptMastery> get conceptMastery => List.unmodifiable(_conceptMastery);
  List<ReviewRecommendation> get dailyReviewQueue =>
      List.unmodifiable(_dailyReviewQueue);
  Object? get error => _error;
  bool get isLoading => _state == AttemptHistoryLoadState.loading;
  int get completedAttemptCount => _entries.length;
  int get totalCorrectAnswers =>
      _entries.fold(0, (total, entry) => total + entry.correctAnswers);
  int get totalQuestions =>
      _entries.fold(0, (total, entry) => total + entry.totalQuestions);
  double get accuracyPercent =>
      totalQuestions == 0 ? 0 : (totalCorrectAnswers / totalQuestions) * 100;
  List<AttemptHistoryEntry> get entriesCompletedToday {
    final today = _now().toLocal();
    return _entries
        .where((entry) => _isSameDay(entry.completedAt.toLocal(), today))
        .toList(growable: false);
  }

  List<AttemptHistoryEntry> get visibleRecentEntries {
    final includedIds = entriesCompletedToday
        .map((entry) => entry.attempt.id)
        .toSet();
    final visible = <AttemptHistoryEntry>[...entriesCompletedToday];
    for (final entry in _entries) {
      if (visible.length >= 5 && includedIds.isNotEmpty) break;
      if (includedIds.add(entry.attempt.id)) visible.add(entry);
    }
    return List.unmodifiable(visible);
  }

  int get questionsCompletedToday {
    return entriesCompletedToday.fold(
      0,
      (total, entry) => total + entry.totalQuestions,
    );
  }

  int get currentStreakDays {
    final completedDays = _entries
        .map((entry) => _dateKey(entry.completedAt.toLocal()))
        .toSet();
    if (completedDays.isEmpty) return 0;

    final now = _now().toLocal();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!completedDays.contains(_dateKey(cursor))) {
      cursor = _previousCalendarDay(cursor);
      if (!completedDays.contains(_dateKey(cursor))) return 0;
    }

    var streak = 0;
    while (completedDays.contains(_dateKey(cursor))) {
      streak++;
      cursor = _previousCalendarDay(cursor);
    }
    return streak;
  }

  Future<void> load() async {
    _state = AttemptHistoryLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final attempts = await attemptRepository.getCompleted();
      final loadedEntries = <AttemptHistoryEntry>[];
      final mastery = <String, _MutableMastery>{};
      final recommendationQuiz = <String, ({String id, String title})>{};
      for (final attempt in attempts) {
        final quiz = await quizRepository.getById(attempt.quizId);
        if (quiz == null) continue;

        final answersByQuestion = {
          for (final answer in attempt.answers) answer.questionId: answer.value,
        };
        var correctAnswers = 0;
        for (final question in quiz.questions) {
          final correct = question.isCorrectAnswer(
            answersByQuestion[question.id],
          );
          if (correct) correctAnswers++;
          for (final concept in question.concepts) {
            final value = mastery.putIfAbsent(
              concept.id,
              () => _MutableMastery(concept),
            );
            value.attempts++;
            if (correct) {
              value.correctAnswers++;
            } else {
              value.lastIncorrectAt = attempt.completedAt ?? attempt.startedAt;
              recommendationQuiz[concept.id] = (id: quiz.id, title: quiz.title);
            }
          }
        }
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
      _conceptMastery = mastery.values.map((value) => value.freeze()).toList()
        ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
      _dailyReviewQueue = _conceptMastery
          .where((item) => item.status != MasteryStatus.mastered)
          .where((item) => recommendationQuiz.containsKey(item.concept.id))
          .take(10)
          .map((item) {
            final quiz = recommendationQuiz[item.concept.id]!;
            return ReviewRecommendation(
              mastery: item,
              quizId: quiz.id,
              quizTitle: quiz.title,
            );
          })
          .toList(growable: false);
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

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  DateTime _previousCalendarDay(DateTime value) =>
      DateTime(value.year, value.month, value.day - 1);
}

class _MutableMastery {
  final Concept concept;
  int correctAnswers = 0;
  int attempts = 0;
  DateTime? lastIncorrectAt;

  _MutableMastery(this.concept);

  ConceptMastery freeze() => ConceptMastery(
    concept: concept,
    correctAnswers: correctAnswers,
    attempts: attempts,
    lastIncorrectAt: lastIncorrectAt,
  );
}
