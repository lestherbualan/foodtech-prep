import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exam_attempt_repository.dart';
import '../../domain/saved_exam_attempt.dart';

/// Provides the [ExamAttemptRepository] singleton.
final examAttemptRepositoryProvider = Provider<ExamAttemptRepository>((ref) {
  return ExamAttemptRepository();
});

/// Fetches recent exam attempts for a given user ID.
/// Refreshable — call `ref.invalidate` after saving a new attempt.
final recentAttemptsProvider =
    FutureProvider.family<List<SavedExamAttempt>, String>((ref, userId) {
      final repo = ref.watch(examAttemptRepositoryProvider);
      return repo.getRecentAttempts(userId);
    });
