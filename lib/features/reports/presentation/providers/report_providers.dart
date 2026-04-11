import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_repository.dart';
import '../../domain/question_report.dart';
import '../../domain/question_report_summary.dart';

// ---------------------------------------------------------------------------
// Report repository
// ---------------------------------------------------------------------------

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// ---------------------------------------------------------------------------
// Admin / reviewer access control
//
// Legacy helper retained for backward compatibility during migration.
// New code should use `userPermissionsProvider` from auth_providers.dart.
// ---------------------------------------------------------------------------

/// @deprecated – use `ref.watch(userPermissionsProvider).canViewReports`
/// instead. Kept temporarily so existing call-sites compile during migration.
bool isAdminUid(String? uid) {
  // Stub: always returns false. Role-based checks are now authoritative.
  return false;
}

// ---------------------------------------------------------------------------
// Report summaries (admin)
// ---------------------------------------------------------------------------

final reportSummariesProvider =
    FutureProvider.autoDispose<List<QuestionReportSummary>>((ref) async {
      final repo = ref.watch(reportRepositoryProvider);
      return repo.getReportSummaries();
    });

// ---------------------------------------------------------------------------
// Single report summary + individual reports (admin detail)
// ---------------------------------------------------------------------------

final reportDetailProvider = FutureProvider.autoDispose
    .family<QuestionReportSummary?, String>((ref, questionId) async {
      final repo = ref.watch(reportRepositoryProvider);
      return repo.getReportSummary(questionId);
    });

final reportsForQuestionProvider = FutureProvider.autoDispose
    .family<List<QuestionReport>, String>((ref, questionId) async {
      final repo = ref.watch(reportRepositoryProvider);
      return repo.getReportsForQuestion(questionId);
    });
