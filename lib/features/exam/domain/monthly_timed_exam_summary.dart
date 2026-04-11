import 'daily_timed_exam_detail.dart';
import 'saved_exam_attempt.dart';

/// Holds all daily timed-exam details for a single calendar month.
class MonthlyTimedExamSummary {
  const MonthlyTimedExamSummary._({
    required this.year,
    required this.month,
    required this.days,
    required Map<int, List<SavedExamAttempt>> attemptsByDay,
  }) : _attemptsByDay = attemptsByDay;

  /// The year being summarised.
  final int year;

  /// The month (1–12) being summarised.
  final int month;

  /// Map of day-of-month (1-based) → detail.
  /// Only days that fall within the month are present.
  final Map<int, DailyTimedExamDetail> days;

  /// Raw timed attempts grouped by day-of-month (most-recent first within each day).
  final Map<int, List<SavedExamAttempt>> _attemptsByDay;

  /// Returns the detail for a specific [date], or an empty detail if no data.
  DailyTimedExamDetail detailFor(DateTime date) {
    return days[date.day] ?? DailyTimedExamDetail.empty(date: date);
  }

  /// Returns the individual timed attempts for a specific [date],
  /// ordered most-recent first. Empty list if no attempts.
  List<SavedExamAttempt> attemptsFor(DateTime date) {
    return _attemptsByDay[date.day] ?? const [];
  }

  /// Builds a monthly summary from [attempts] for the given [year]/[month].
  ///
  /// Only attempts whose [SavedExamAttempt.mode] is `'timed'` are included.
  factory MonthlyTimedExamSummary.fromAttempts(
    int year,
    int month,
    List<SavedExamAttempt> attempts,
  ) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Filter timed-only, group by day-of-month.
    final grouped = <int, List<SavedExamAttempt>>{};
    for (final a in attempts) {
      if (a.mode != 'timed') continue;
      final d = DateTime(
        a.submittedAt.year,
        a.submittedAt.month,
        a.submittedAt.day,
      );
      if (d.year != year || d.month != month) continue;
      (grouped[d.day] ??= []).add(a);
    }

    final days = <int, DailyTimedExamDetail>{};
    for (var i = 1; i <= daysInMonth; i++) {
      final date = DateTime(year, month, i);
      final dayAttempts = grouped[i];
      days[i] = dayAttempts != null && dayAttempts.isNotEmpty
          ? DailyTimedExamDetail.fromAttempts(date, dayAttempts)
          : DailyTimedExamDetail.empty(date: date);
    }

    return MonthlyTimedExamSummary._(
      year: year,
      month: month,
      days: days,
      attemptsByDay: grouped,
    );
  }

  /// First date of this month.
  DateTime get firstDate => DateTime(year, month, 1);

  /// Number of days in this month.
  int get daysInMonth => DateTime(year, month + 1, 0).day;
}
