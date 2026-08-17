/// A single selectable answer within a [QuizQuestion].
class QuizOption {
  final String id;
  final String text;

  QuizOption({required this.id, required this.text});
}

/// One question inside a [Quiz], supporting multiple question types.
class QuizQuestion {
  final int number;
  final String prompt;
  final List<QuizOption> options;
  final String correctOptionId;

  /// The kind of question: `'multiple_choice'`, `'fill_blank'`, or
  /// `'translation'`.
  final String type;

  /// The id of the option the user selected, or `null` if unanswered.
  String? selectedOptionId;

  QuizQuestion({
    required this.number,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    this.type = 'multiple_choice',
    this.selectedOptionId,
  });

  /// Whether the user's selection matches the correct answer.
  bool get isCorrect => selectedOptionId == correctOptionId;

  /// Whether the user has made a selection.
  bool get isAnswered => selectedOptionId != null;
}

/// A complete quiz containing an ordered list of [QuizQuestion]s.
class Quiz {
  final String id;
  final String title;
  final String source;
  final List<QuizQuestion> questions;
  final DateTime? completedAt;

  Quiz({
    required this.id,
    required this.title,
    required this.source,
    required this.questions,
    this.completedAt,
  });

  int get totalQuestions => questions.length;

  int get answeredCount => questions.where((q) => q.isAnswered).length;

  int get correctCount => questions.where((q) => q.isCorrect).length;

  int get incorrectCount =>
      questions.where((q) => q.isAnswered && !q.isCorrect).length;

  int get unansweredCount => totalQuestions - answeredCount;

  double get scorePercent =>
      totalQuestions == 0 ? 0 : (correctCount / totalQuestions) * 100;

  List<QuizQuestion> get incorrectQuestions =>
      questions.where((q) => q.isAnswered && !q.isCorrect).toList();
}
