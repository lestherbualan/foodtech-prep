import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/monthly_timed_exam_summary.dart';
import 'exam_attempt_providers.dart';

/// Composite key for the monthly provider: userId + year + month.
typedef MonthlyKey = ({String userId, int year, int month});

/// Provides a [MonthlyTimedExamSummary] for the requested month,
/// loaded directly from Firestore for the full month range.
final monthlyTimedExamSummaryProvider =
    FutureProvider.family<MonthlyTimedExamSummary, MonthlyKey>((
      ref,
      key,
    ) async {
      final repo = ref.watch(examAttemptRepositoryProvider);

      final firstDay = DateTime(key.year, key.month, 1);
      final lastDay = DateTime(key.year, key.month + 1, 0); // last day of month

      final attempts = await repo.getAttemptsForDateRange(
        key.userId,
        start: firstDay,
        end: lastDay,
      );

      return MonthlyTimedExamSummary.fromAttempts(
        key.year,
        key.month,
        attempts,
      );
    });
