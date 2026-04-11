/// Summary of timed exam performance for a single calendar day.
class DailyTimedExamSummary {
  const DailyTimedExamSummary({
    required this.date,
    required this.timedExamCount,
    required this.averageScore,
    required this.hasAttempt,
  });

  /// The calendar date (time component should be midnight local).
  final DateTime date;

  /// Number of timed exam attempts on this day.
  final int timedExamCount;

  /// Average score (0–100) across timed exams, or null if no attempts.
  final double? averageScore;

  /// Whether at least one timed exam was taken on this day.
  final bool hasAttempt;

  /// Creates a summary representing a day with no timed exam activity.
  const DailyTimedExamSummary.empty({required this.date})
    : timedExamCount = 0,
      averageScore = null,
      hasAttempt = false;
}
