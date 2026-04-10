import 'saved_exam_attempt.dart';

/// Detailed summary of timed exam performance for a single calendar day.
///
/// Extends the information from the lightweight [DailyTimedExamSummary] used by
/// the weekly strip with best/lowest scores and total question counts needed
/// by the monthly calendar's daily detail panel.
class DailyTimedExamDetail {
  const DailyTimedExamDetail({
    required this.date,
    required this.timedExamCount,
    required this.averageScore,
    required this.bestScore,
    required this.lowestScore,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.hasAttempt,
  });

  /// The calendar date (midnight local).
  final DateTime date;

  /// Number of timed exam attempts on this day.
  final int timedExamCount;

  /// Average score (0–100) across timed exams, or null if no attempts.
  final double? averageScore;

  /// Best single-exam score of the day, or null if no attempts.
  final double? bestScore;

  /// Lowest single-exam score of the day, or null if no attempts.
  final double? lowestScore;

  /// Total questions answered across all timed exams this day.
  final int totalQuestions;

  /// Total correct answers across all timed exams this day.
  final int totalCorrect;

  /// Whether at least one timed exam was taken on this day.
  final bool hasAttempt;

  /// Creates a detail representing a day with no timed exam activity.
  const DailyTimedExamDetail.empty({required this.date})
    : timedExamCount = 0,
      averageScore = null,
      bestScore = null,
      lowestScore = null,
      totalQuestions = 0,
      totalCorrect = 0,
      hasAttempt = false;

  /// Builds a [DailyTimedExamDetail] from a list of timed attempts for one day.
  factory DailyTimedExamDetail.fromAttempts(
    DateTime date,
    List<SavedExamAttempt> attempts,
  ) {
    if (attempts.isEmpty) return DailyTimedExamDetail.empty(date: date);

    final scores = attempts.map((a) => a.scorePercent).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.reduce((a, b) => a > b ? a : b);
    final lowest = scores.reduce((a, b) => a < b ? a : b);
    final totalQ = attempts.fold<int>(0, (s, a) => s + a.totalQuestions);
    final totalC = attempts.fold<int>(0, (s, a) => s + a.correctCount);

    return DailyTimedExamDetail(
      date: date,
      timedExamCount: attempts.length,
      averageScore: avg,
      bestScore: best,
      lowestScore: lowest,
      totalQuestions: totalQ,
      totalCorrect: totalC,
      hasAttempt: true,
    );
  }
}
