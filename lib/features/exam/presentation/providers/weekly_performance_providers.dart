import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/weekly_timed_exam_summary.dart';
import 'exam_attempt_providers.dart';

/// Provides a [WeeklyTimedExamSummary] for the current week,
/// loaded directly from Firestore for the Sunday–Saturday range.
final weeklyTimedExamSummaryProvider =
    FutureProvider.family<WeeklyTimedExamSummary, String>((ref, userId) async {
      final repo = ref.watch(examAttemptRepositoryProvider);

      // Compute current week boundaries.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysSinceSunday = today.weekday % 7;
      final sunday = today.subtract(Duration(days: daysSinceSunday));
      final saturday = sunday.add(const Duration(days: 6));

      final attempts = await repo.getAttemptsForDateRange(
        userId,
        start: sunday,
        end: saturday,
      );
      return WeeklyTimedExamSummary.fromAttempts(attempts);
    });
