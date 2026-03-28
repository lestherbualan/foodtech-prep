import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dashboard_stats.dart';
import 'exam_attempt_providers.dart';

/// Computes [DashboardStats] from the user's recent attempts.
final dashboardStatsProvider = FutureProvider.family<DashboardStats, String>((
  ref,
  userId,
) async {
  final attempts = await ref.watch(recentAttemptsProvider(userId).future);
  return DashboardStats.compute(attempts);
});
