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
// ---------------------------------------------------------------------------

/// Current admin/reviewer UIDs. Structured as a Set so additional
/// reviewer accounts can be added later without refactoring.
const Set<String> _adminUids = {'drRxvYrl2yfJZaggkgpxOUJeotj2'};

/// Returns true if [uid] has admin/reviewer access.
bool isAdminUid(String? uid) {
  if (uid == null || uid.isEmpty) return false;
  return _adminUids.contains(uid);
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
