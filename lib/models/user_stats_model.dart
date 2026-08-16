/// Aggregate statistics for a quizMoi user.
class UserStats {
  final String name;
  final String level;
  final int xp;
  final double averageScore;
  final int dailyGoalCurrent;
  final int dailyGoalTarget;
  final int streakDays;

  UserStats({
    required this.name,
    required this.level,
    required this.xp,
    required this.averageScore,
    required this.dailyGoalCurrent,
    required this.dailyGoalTarget,
    required this.streakDays,
  });

  /// Progress toward today's goal as a value between 0.0 and 1.0.
  double get dailyGoalPercent =>
      dailyGoalTarget == 0 ? 0 : dailyGoalCurrent / dailyGoalTarget;
}
