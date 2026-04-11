import 'package:cloud_firestore/cloud_firestore.dart';

/// Issue type labels for question reports.
class ReportIssueType {
  ReportIssueType._();

  static const String wrongQuestion = 'Wrong question';
  static const String wrongChoices = 'Wrong choices';
  static const String wrongExplanation = 'Wrong explanation';
  static const String unclearWording = 'Unclear wording';
  static const String wrongTopic = 'Wrong topic';
  static const String typoGrammar = 'Typo / grammar';
  static const String other = 'Other';

  static const List<String> all = [
    wrongQuestion,
    wrongChoices,
    wrongExplanation,
    unclearWording,
    wrongTopic,
    typoGrammar,
    other,
  ];
}

/// The context from which a report was submitted.
enum ReportContext {
  practice,
  timedExam;

  String get label {
    switch (this) {
      case ReportContext.practice:
        return 'practice';
      case ReportContext.timedExam:
        return 'timed_exam';
    }
  }

  static ReportContext fromString(String value) {
    switch (value) {
      case 'timed_exam':
        return ReportContext.timedExam;
      default:
        return ReportContext.practice;
    }
  }
}

/// A single report submitted by a user about a question.
class QuestionReport {
  const QuestionReport({
    required this.reportId,
    required this.questionId,
    required this.subjectId,
    required this.subjectName,
    required this.subtopicId,
    required this.subtopicName,
    required this.questionTextPreview,
    required this.reportedByUid,
    required this.reportedByDisplayName,
    required this.reportedByEmail,
    required this.reportedAt,
    required this.context,
    required this.issueTypes,
    this.note,
    this.examAttemptId,
  });

  final String reportId;
  final String questionId;
  final String subjectId;
  final String subjectName;
  final String subtopicId;
  final String subtopicName;
  final String questionTextPreview;
  final String reportedByUid;
  final String reportedByDisplayName;
  final String reportedByEmail;
  final DateTime reportedAt;
  final ReportContext context;
  final List<String> issueTypes;
  final String? note;
  final String? examAttemptId;

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subtopicId': subtopicId,
      'subtopicName': subtopicName,
      'questionTextPreview': questionTextPreview,
      'reportedByUid': reportedByUid,
      'reportedByDisplayName': reportedByDisplayName,
      'reportedByEmail': reportedByEmail,
      'reportedAt': FieldValue.serverTimestamp(),
      'context': context.label,
      'issueTypes': issueTypes,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (examAttemptId != null) 'examAttemptId': examAttemptId,
    };
  }

  factory QuestionReport.fromFirestore(String id, Map<String, dynamic> data) {
    return QuestionReport(
      reportId: id,
      questionId: data['questionId'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
      subjectName: data['subjectName'] as String? ?? '',
      subtopicId: data['subtopicId'] as String? ?? '',
      subtopicName: data['subtopicName'] as String? ?? '',
      questionTextPreview: data['questionTextPreview'] as String? ?? '',
      reportedByUid: data['reportedByUid'] as String? ?? '',
      reportedByDisplayName: data['reportedByDisplayName'] as String? ?? '',
      reportedByEmail: data['reportedByEmail'] as String? ?? '',
      reportedAt: _parseTimestamp(data['reportedAt']),
      context: ReportContext.fromString(data['context'] as String? ?? ''),
      issueTypes: List<String>.from(data['issueTypes'] as List? ?? []),
      note: data['note'] as String?,
      examAttemptId: data['examAttemptId'] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
