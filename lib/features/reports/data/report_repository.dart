import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    final batch = _firestore.batch();

    // 1. Create the individual report document.
    final reportDoc = _reportsRef.doc();
    batch.set(reportDoc, report.toFirestore());

    // 2. Update the question-level summary (create or merge).
    final summaryDoc = _summariesRef.doc(report.questionId);

    // Build the issue type increment map.
    final issueIncrements = <String, dynamic>{};
    for (final issue in report.issueTypes) {
      issueIncrements['issueTypeCounts.$issue'] = FieldValue.increment(1);
    }

    batch.set(summaryDoc, {
      'questionId': report.questionId,
      'subjectId': report.subjectId,
      'subjectName': report.subjectName,
      'subtopicId': report.subtopicId,
      'subtopicName': report.subtopicName,
      'questionTextPreview': report.questionTextPreview,
      'reportCount': FieldValue.increment(1),
      'latestReportedAt': FieldValue.serverTimestamp(),
      'latestReportedByUid': report.reportedByUid,
      // uniqueReporterCount will be set separately via a read-then-write
      // but we do a simple increment here; the admin detail view shows
      // distinct reporters from the reports sub-collection.
      ...issueIncrements,
    }, SetOptions(merge: true));

    await batch.commit();

    // Update unique reporter count (requires a read, can't be in batch).
    await _updateUniqueReporterCount(report.questionId);

    debugPrint('[ReportRepo] Submitted report for ${report.questionId}');
  }

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
      Query<Map<String, dynamic>> query = _summariesRef.orderBy(
        'latestReportedAt',
        descending: true,
      );

      if (statusFilter != null) {
        query = query.where('reviewStatus', isEqualTo: statusFilter.label);
      }
      if (subjectFilter != null) {
        query = query.where('subjectId', isEqualTo: subjectFilter);
      }

      final snapshot = await query.get();
      final summaries = <QuestionReportSummary>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Ensure reviewStatus field exists
        if (data['reviewStatus'] == null) {
          await _ensureReviewStatus(doc.id);
          data['reviewStatus'] = 'open';
        }
        summaries.add(QuestionReportSummary.fromFirestore(doc.id, data));
      }

      return summaries;
    } catch (e) {
      debugPrint('[ReportRepo] Failed to load summaries: $e');
      rethrow;
    }
  }

  /// Loads a single report summary by question ID.
  Future<QuestionReportSummary?> getReportSummary(String questionId) async {
    try {
      final doc = await _summariesRef.doc(questionId).get();
      if (!doc.exists) return null;
      return QuestionReportSummary.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('[ReportRepo] Failed to load summary $questionId: $e');
      rethrow;
    }
  }

  /// Loads all individual reports for a specific question.
  Future<List<QuestionReport>> getReportsForQuestion(String questionId) async {
    try {
      final snapshot = await _reportsRef
          .where('questionId', isEqualTo: questionId)
          .orderBy('reportedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuestionReport.fromFirestore(doc.id, doc.data()))
          .toList();
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

      if (adminNote != null) {
        updates['adminNote'] = adminNote;
      }

      await _summariesRef.doc(questionId).update(updates);
      debugPrint('[ReportRepo] Updated review status for $questionId');
    } catch (e) {
      debugPrint('[ReportRepo] Failed to update review status: $e');
      rethrow;
    }
  }
}
