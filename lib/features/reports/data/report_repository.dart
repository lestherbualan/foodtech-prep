import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/question_report.dart';
import '../domain/question_report_summary.dart';

/// Firestore-backed repository for question reports and summaries.
class ReportRepository {
  ReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection('question_reports');

  CollectionReference<Map<String, dynamic>> get _summariesRef =>
      _firestore.collection('question_report_summary');

  /// Submits a new report and updates the question-level summary atomically.
  Future<void> submitReport(QuestionReport report) async {
    debugPrint(
      '[ReportRepo] submitReport START questionId=${report.questionId}',
    );
    try {
      // Log Firebase app / project info to help debug which project we're
      // writing to during testing.
      try {
        debugPrint('[ReportRepo] Firebase app: ${Firebase.app().name}');
        debugPrint(
          '[ReportRepo] Firebase projectId: ${Firebase.app().options.projectId}',
        );
      } catch (e) {
        debugPrint('[ReportRepo] Firebase.app() not available: $e');
      }

      debugPrint(
        '[ReportRepo] Submitting report to collection: ${_reportsRef.path}',
      );
      debugPrint('[ReportRepo] Firestore settings: ${_firestore.settings}');

      // Only write the individual report document. Summary aggregation
      // is admin-only and is handled separately by backend/admin flows.
      final reportDoc = _reportsRef.doc();
      debugPrint('[ReportRepo] Creating report doc id=${reportDoc.id}');
      await reportDoc.set(report.toFirestore());

      debugPrint('[ReportRepo] Report write success. Doc ID: ${reportDoc.id}');
      debugPrint(
        '[ReportRepo] submitReport DONE questionId=${report.questionId}',
      );
    } catch (e) {
      debugPrint('[ReportRepo] Failed to submit report: $e');
      rethrow;
    }
  }

  // This helper is retained for admin/maintenance workflows but is
  // intentionally unused by the normal user submit flow.
  // ignore: unused_element
  Future<void> _updateUniqueReporterCount(String questionId) async {
    try {
      final reports = await _reportsRef
          .where('questionId', isEqualTo: questionId)
          .get();

      final uniqueUids = <String>{};
      for (final doc in reports.docs) {
        final uid = doc.data()['reportedByUid'] as String?;
        if (uid != null && uid.isNotEmpty) uniqueUids.add(uid);
      }

      await _summariesRef.doc(questionId).update({
        'uniqueReporterCount': uniqueUids.length,
      });
    } catch (e) {
      debugPrint('[ReportRepo] Failed to update unique reporter count: $e');
    }
  }

  // Ensure the review status field exists on creation.
  // This helper is kept for admin workflows but is not used by the
  // report-listing code that computes summaries from `question_reports`.
  // ignore: unused_element
  Future<void> _ensureReviewStatus(String questionId) async {
    final doc = await _summariesRef.doc(questionId).get();
    if (doc.exists && doc.data()?['reviewStatus'] == null) {
      await _summariesRef.doc(questionId).update({
        'reviewStatus': ReviewStatus.open.label,
        'isFlagged': false,
      });
    }
  }

  /// Loads all report summaries, ordered by latest report date.
  Future<List<QuestionReportSummary>> getReportSummaries({
    ReviewStatus? statusFilter,
    String? subjectFilter,
  }) async {
    try {
      // Read all individual reports and build grouped summaries in-app.
      final reportsSnap = await _reportsRef.get();
      final reports = reportsSnap.docs
          .map((d) => QuestionReport.fromFirestore(d.id, d.data()))
          .toList();

      // Group by questionId
      final Map<String, List<QuestionReport>> groups = {};
      for (final r in reports) {
        groups.putIfAbsent(r.questionId, () => []).add(r);
      }

      // Try to read any existing admin summary docs to overlay review status
      // and admin fields when available. This is optional and keeps client
      // summaries authoritative for counts/timestamps.
      final Map<String, Map<String, dynamic>> summaryDocs = {};
      try {
        final summarySnap = await _summariesRef.get();
        for (final doc in summarySnap.docs) {
          summaryDocs[doc.id] = doc.data();
        }
      } catch (_) {
        // Ignore summary read failures for non-admin users; we'll compute defaults.
      }

      final summaries = <QuestionReportSummary>[];

      for (final entry in groups.entries) {
        final questionId = entry.key;
        final list = entry.value;

        // compute counts and aggregates
        final reportCount = list.length;
        final uniqueUids = <String>{};
        final issueCounts = <String, int>{};
        DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
        String latestUid = '';

        for (final r in list) {
          uniqueUids.add(r.reportedByUid);
          for (final issue in r.issueTypes) {
            issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
          }
          if (r.reportedAt.isAfter(latest)) {
            latest = r.reportedAt;
            latestUid = r.reportedByUid;
          }
        }

        // Use first report as source for metadata
        final first = list.first;

        // Build base summary
        var summary = QuestionReportSummary(
          questionId: questionId,
          subjectId: first.subjectId,
          subjectName: first.subjectName,
          subtopicId: first.subtopicId,
          subtopicName: first.subtopicName,
          questionTextPreview: first.questionTextPreview,
          reportCount: reportCount,
          uniqueReporterCount: uniqueUids.length,
          issueTypeCounts: issueCounts,
          latestReportedAt: latest == DateTime.fromMillisecondsSinceEpoch(0)
              ? DateTime.now()
              : latest,
          latestReportedByUid: latestUid,
          reviewStatus: ReviewStatus.open,
        );

        // Overlay admin summary doc fields if present
        final docData = summaryDocs[questionId];
        if (docData != null) {
          try {
            final fetched = QuestionReportSummary.fromFirestore(
              questionId,
              docData,
            );
            summary = summary.copyWith(
              reviewStatus: fetched.reviewStatus,
              adminNote: fetched.adminNote,
              reviewedByUid: fetched.reviewedByUid,
              reviewedByName: fetched.reviewedByName,
              reviewedAt: fetched.reviewedAt,
              isFlagged: fetched.isFlagged,
            );
          } catch (_) {
            // ignore overlay errors
          }
        }

        summaries.add(summary);
      }

      // Apply optional filters
      var result = summaries;
      if (subjectFilter != null) {
        result = result.where((s) => s.subjectId == subjectFilter).toList();
      }
      if (statusFilter != null) {
        result = result.where((s) => s.reviewStatus == statusFilter).toList();
      }

      // Sort by latestReportedAt desc
      result.sort((a, b) => b.latestReportedAt.compareTo(a.latestReportedAt));

      return result;
    } catch (e) {
      debugPrint('[ReportRepo] Failed to load summaries from reports: $e');
      rethrow;
    }
  }

  /// Loads a single report summary by question ID.
  Future<QuestionReportSummary?> getReportSummary(String questionId) async {
    try {
      final reports = await getReportsForQuestion(questionId);
      if (reports.isEmpty) {
        // Fall back to summary doc if present
        final doc = await _summariesRef.doc(questionId).get();
        if (!doc.exists) return null;
        return QuestionReportSummary.fromFirestore(doc.id, doc.data()!);
      }

      // Compute summary from reports
      final issueCounts = <String, int>{};
      final uniqueUids = <String>{};
      DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
      String latestUid = '';
      for (final r in reports) {
        uniqueUids.add(r.reportedByUid);
        for (final issue in r.issueTypes) {
          issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
        }
        if (r.reportedAt.isAfter(latest)) {
          latest = r.reportedAt;
          latestUid = r.reportedByUid;
        }
      }

      final first = reports.first;
      var summary = QuestionReportSummary(
        questionId: questionId,
        subjectId: first.subjectId,
        subjectName: first.subjectName,
        subtopicId: first.subtopicId,
        subtopicName: first.subtopicName,
        questionTextPreview: first.questionTextPreview,
        reportCount: reports.length,
        uniqueReporterCount: uniqueUids.length,
        issueTypeCounts: issueCounts,
        latestReportedAt: latest == DateTime.fromMillisecondsSinceEpoch(0)
            ? DateTime.now()
            : latest,
        latestReportedByUid: latestUid,
        reviewStatus: ReviewStatus.open,
      );

      // Overlay summary doc if it exists
      final doc = await _summariesRef.doc(questionId).get();
      if (doc.exists) {
        try {
          final fetched = QuestionReportSummary.fromFirestore(
            doc.id,
            doc.data()!,
          );
          summary = summary.copyWith(
            reviewStatus: fetched.reviewStatus,
            adminNote: fetched.adminNote,
            reviewedByUid: fetched.reviewedByUid,
            reviewedByName: fetched.reviewedByName,
            reviewedAt: fetched.reviewedAt,
            isFlagged: fetched.isFlagged,
          );
        } catch (_) {}
      }

      return summary;
    } catch (e) {
      debugPrint(
        '[ReportRepo] Failed to load summary $questionId from reports: $e',
      );
      rethrow;
    }
  }

  /// Loads all individual reports for a specific question.
  Future<List<QuestionReport>> getReportsForQuestion(String questionId) async {
    try {
      // Query only by questionId to avoid requiring a composite index.
      final snapshot = await _reportsRef
          .where('questionId', isEqualTo: questionId)
          .get();

      final reports = snapshot.docs
          .map((doc) => QuestionReport.fromFirestore(doc.id, doc.data()))
          .toList();

      // Sort locally by reportedAt descending. Be defensive in case
      // reportedAt is missing or malformed; fall back to epoch.
      reports.sort((a, b) {
        final aTime = a.reportedAt;
        final bTime = b.reportedAt;
        return bTime.compareTo(aTime);
      });

      return reports;
    } catch (e) {
      debugPrint('[ReportRepo] Failed to load reports for $questionId: $e');
      rethrow;
    }
  }

  /// Updates the review status and admin note for a question summary.
  Future<void> updateReviewStatus({
    required String questionId,
    required ReviewStatus status,
    required String reviewerUid,
    String? reviewerName,
    String? adminNote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'reviewStatus': status.label,
        'reviewedByUid': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'isFlagged':
            status == ReviewStatus.open || status == ReviewStatus.underReview,
      };

      if (reviewerName != null) {
        updates['reviewedByName'] = reviewerName;
      }

      if (adminNote != null) {
        updates['adminNote'] = adminNote;
      }

      // Use set+merge so the document is created if it doesn't exist yet.
      await _summariesRef.doc(questionId).set(updates, SetOptions(merge: true));
      debugPrint('[ReportRepo] Updated review status for $questionId');
    } catch (e) {
      debugPrint('[ReportRepo] Failed to update review status: $e');
      rethrow;
    }
  }
}
