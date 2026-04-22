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
    // Assignment / under review
    this.assignedReviewerUid,
    this.assignedReviewerName,
    this.assignedAt,
    // Resolution
    this.resolvedByUid,
    this.resolvedByName,
    this.resolvedAt,
    this.resolutionNote,
    // Rejection
    this.rejectedByUid,
    this.rejectedByName,
    this.rejectedAt,
    this.rejectionReason,
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

  // Assignment / under review
  final String? assignedReviewerUid;
  final String? assignedReviewerName;
  final DateTime? assignedAt;

  // Resolution
  final String? resolvedByUid;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? resolutionNote;

  // Rejection
  final String? rejectedByUid;
  final String? rejectedByName;
  final DateTime? rejectedAt;
  final String? rejectionReason;

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
      if (assignedReviewerUid != null)
        'assignedReviewerUid': assignedReviewerUid,
      if (assignedReviewerName != null)
        'assignedReviewerName': assignedReviewerName,
      if (assignedAt != null) 'assignedAt': Timestamp.fromDate(assignedAt!),
      if (resolvedByUid != null) 'resolvedByUid': resolvedByUid,
      if (resolvedByName != null) 'resolvedByName': resolvedByName,
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      if (rejectedByUid != null) 'rejectedByUid': rejectedByUid,
      if (rejectedByName != null) 'rejectedByName': rejectedByName,
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
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
      assignedReviewerUid: data['assignedReviewerUid'] as String?,
      assignedReviewerName: data['assignedReviewerName'] as String?,
      assignedAt: data['assignedAt'] != null
          ? _parseTimestamp(data['assignedAt'])
          : null,
      resolvedByUid: data['resolvedByUid'] as String?,
      resolvedByName: data['resolvedByName'] as String?,
      resolvedAt: data['resolvedAt'] != null
          ? _parseTimestamp(data['resolvedAt'])
          : null,
      resolutionNote: data['resolutionNote'] as String?,
      rejectedByUid: data['rejectedByUid'] as String?,
      rejectedByName: data['rejectedByName'] as String?,
      rejectedAt: data['rejectedAt'] != null
          ? _parseTimestamp(data['rejectedAt'])
          : null,
      rejectionReason: data['rejectionReason'] as String?,
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
    String? assignedReviewerUid,
    String? assignedReviewerName,
    DateTime? assignedAt,
    String? resolvedByUid,
    String? resolvedByName,
    DateTime? resolvedAt,
    String? resolutionNote,
    String? rejectedByUid,
    String? rejectedByName,
    DateTime? rejectedAt,
    String? rejectionReason,
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
      assignedReviewerUid: assignedReviewerUid ?? this.assignedReviewerUid,
      assignedReviewerName: assignedReviewerName ?? this.assignedReviewerName,
      assignedAt: assignedAt ?? this.assignedAt,
      resolvedByUid: resolvedByUid ?? this.resolvedByUid,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      rejectedByUid: rejectedByUid ?? this.rejectedByUid,
      rejectedByName: rejectedByName ?? this.rejectedByName,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
