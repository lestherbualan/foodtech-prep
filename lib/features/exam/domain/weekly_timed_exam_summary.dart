import 'daily_timed_exam_summary.dart';
import 'saved_exam_attempt.dart';

/// Computes a 7-day (Sunday → Saturday) weekly summary of timed exam
/// performance from a list of [SavedExamAttempt]s.
class WeeklyTimedExamSummary {
  const WeeklyTimedExamSummary._({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
  });

  /// The Sunday that starts this week (midnight local).
  final DateTime weekStart;

  /// The Saturday that ends this week (midnight local).
  final DateTime weekEnd;

  /// Exactly 7 summaries, indexed Sunday (0) → Saturday (6).
  final List<DailyTimedExamSummary> days;

  /// Builds the summary for the current week from the given [attempts].
  ///
  /// Only attempts whose [SavedExamAttempt.mode] is `'timed'` are included.
  factory WeeklyTimedExamSummary.fromAttempts(List<SavedExamAttempt> attempts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // DateTime.weekday: Monday=1 … Sunday=7.
    // We want Sunday as the start of the week.
    final daysSinceSunday = today.weekday % 7; // Sunday→0, Mon→1 … Sat→6
    final sunday = today.subtract(Duration(days: daysSinceSunday));
    final saturday = sunday.add(const Duration(days: 6));

    // Filter to timed-only attempts within this week.
    final timedThisWeek = attempts.where((a) {
      if (a.mode != 'timed') return false;
      final d = DateTime(
        a.submittedAt.year,
        a.submittedAt.month,
        a.submittedAt.day,
      );
      return !d.isBefore(sunday) && !d.isAfter(saturday);
    }).toList();

    // Group by day offset (0 = Sunday … 6 = Saturday).
    final grouped = <int, List<SavedExamAttempt>>{};
    for (final a in timedThisWeek) {
      final d = DateTime(
        a.submittedAt.year,
        a.submittedAt.month,
        a.submittedAt.day,
      );
      final offset = d.difference(sunday).inDays;
      (grouped[offset] ??= []).add(a);
    }

    final days = List<DailyTimedExamSummary>.generate(7, (i) {
      final date = sunday.add(Duration(days: i));
      final dayAttempts = grouped[i];
      if (dayAttempts == null || dayAttempts.isEmpty) {
        return DailyTimedExamSummary.empty(date: date);
      }
      final avg =
          dayAttempts.map((a) => a.scorePercent).reduce((a, b) => a + b) /
          dayAttempts.length;
      return DailyTimedExamSummary(
        date: date,
        timedExamCount: dayAttempts.length,
        averageScore: avg,
        hasAttempt: true,
      );
    });

    return WeeklyTimedExamSummary._(
      weekStart: sunday,
      weekEnd: saturday,
      days: days,
    );
  }
}
