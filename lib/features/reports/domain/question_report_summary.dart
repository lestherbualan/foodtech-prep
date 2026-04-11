import 'package:cloud_firestore/cloud_firestore.dart';

/// Review status for a reported question.
enum ReviewStatus {
  open,
  underReview,
  resolved,
  rejected;

  String get label {
    switch (this) {
      case ReviewStatus.open:
        return 'open';
      case ReviewStatus.underReview:
        return 'under_review';
      case ReviewStatus.resolved:
        return 'resolved';
      case ReviewStatus.rejected:
        return 'rejected';
    }
  }

  String get displayLabel {
    switch (this) {
      case ReviewStatus.open:
        return 'Open';
      case ReviewStatus.underReview:
        return 'Under Review';
      case ReviewStatus.resolved:
        return 'Resolved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }

  static ReviewStatus fromString(String value) {
    switch (value) {
      case 'under_review':
        return ReviewStatus.underReview;
      case 'resolved':
      case 'fixed': // backward compat
        return ReviewStatus.resolved;
      case 'rejected':
      case 'dismissed': // backward compat
        return ReviewStatus.rejected;
      default:
        return ReviewStatus.open;
    }
  }
}

/// Aggregated summary of reports for a single question.
class QuestionReportSummary {
  const QuestionReportSummary({
    required this.questionId,
    required this.subjectId,
    required this.subjectName,
    required this.subtopicId,
    required this.subtopicName,
    required this.questionTextPreview,
    required this.reportCount,
    required this.uniqueReporterCount,
    required this.issueTypeCounts,
    required this.latestReportedAt,
    required this.latestReportedByUid,
    required this.reviewStatus,
    this.isFlagged = false,
    this.adminNote,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewedAt,
  });

  final String questionId;
  final String subjectId;
  final String subjectName;
  final String subtopicId;
  final String subtopicName;
  final String questionTextPreview;
  final int reportCount;
  final int uniqueReporterCount;
  final Map<String, int> issueTypeCounts;
  final DateTime latestReportedAt;
  final String latestReportedByUid;
  final ReviewStatus reviewStatus;
  final bool isFlagged;
  final String? adminNote;
  final String? reviewedByUid;
  final String? reviewedByName;
  final DateTime? reviewedAt;

  /// Top issue types sorted by count descending.
  List<String> get topIssueTypes {
    final sorted = issueTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subtopicId': subtopicId,
      'subtopicName': subtopicName,
      'questionTextPreview': questionTextPreview,
      'reportCount': reportCount,
      'uniqueReporterCount': uniqueReporterCount,
      'issueTypeCounts': issueTypeCounts,
      'latestReportedAt': Timestamp.fromDate(latestReportedAt),
      'latestReportedByUid': latestReportedByUid,
      'reviewStatus': reviewStatus.label,
      'isFlagged': isFlagged,
      if (adminNote != null) 'adminNote': adminNote,
      if (reviewedByUid != null) 'reviewedByUid': reviewedByUid,
      if (reviewedByName != null) 'reviewedByName': reviewedByName,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  factory QuestionReportSummary.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return QuestionReportSummary(
      questionId: id,
      subjectId: data['subjectId'] as String? ?? '',
      subjectName: data['subjectName'] as String? ?? '',
      subtopicId: data['subtopicId'] as String? ?? '',
      subtopicName: data['subtopicName'] as String? ?? '',
      questionTextPreview: data['questionTextPreview'] as String? ?? '',
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      uniqueReporterCount: (data['uniqueReporterCount'] as num?)?.toInt() ?? 0,
      issueTypeCounts: _parseIssueTypeCounts(data['issueTypeCounts']),
      latestReportedAt: _parseTimestamp(data['latestReportedAt']),
      latestReportedByUid: data['latestReportedByUid'] as String? ?? '',
      reviewStatus: ReviewStatus.fromString(
        data['reviewStatus'] as String? ?? '',
      ),
      isFlagged: data['isFlagged'] as bool? ?? false,
      adminNote: data['adminNote'] as String?,
      reviewedByUid: data['reviewedByUid'] as String?,
      reviewedByName: data['reviewedByName'] as String?,
      reviewedAt: data['reviewedAt'] != null
          ? _parseTimestamp(data['reviewedAt'])
          : null,
    );
  }

  static Map<String, int> _parseIssueTypeCounts(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), (val as num?)?.toInt() ?? 0),
      );
    }
    return {};
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  QuestionReportSummary copyWith({
    ReviewStatus? reviewStatus,
    String? adminNote,
    String? reviewedByUid,
    String? reviewedByName,
    DateTime? reviewedAt,
    bool? isFlagged,
  }) {
    return QuestionReportSummary(
      questionId: questionId,
      subjectId: subjectId,
      subjectName: subjectName,
      subtopicId: subtopicId,
      subtopicName: subtopicName,
      questionTextPreview: questionTextPreview,
      reportCount: reportCount,
      uniqueReporterCount: uniqueReporterCount,
      issueTypeCounts: issueTypeCounts,
      latestReportedAt: latestReportedAt,
      latestReportedByUid: latestReportedByUid,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      isFlagged: isFlagged ?? this.isFlagged,
      adminNote: adminNote ?? this.adminNote,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
