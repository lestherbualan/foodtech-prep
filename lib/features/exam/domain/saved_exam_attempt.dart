import 'package:cloud_firestore/cloud_firestore.dart';

import 'exam_models.dart';

/// A persisted exam attempt record for the user's history.
class SavedExamAttempt {
  const SavedExamAttempt({
    required this.attemptId,
    required this.userId,
    required this.mode,
    required this.submittedAt,
    required this.timeLimitSeconds,
    required this.timeSpentSeconds,
    required this.wasAutoSubmitted,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.scorePercent,
    this.strongestSubject,
    this.weakestSubject,
  });

  final String attemptId;
  final String userId;
  final String mode; // 'timed'
  final DateTime submittedAt;
  final int timeLimitSeconds;
  final int timeSpentSeconds;
  final bool wasAutoSubmitted;
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
  final double scorePercent;
  final String? strongestSubject;
  final String? weakestSubject;

  /// Creates a [SavedExamAttempt] from an [ExamResult] and user metadata.
  factory SavedExamAttempt.fromResult({
    required ExamResult result,
    required String userId,
    required int timeLimitSeconds,
  }) {
    final breakdown = result.performanceBreakdown;
    return SavedExamAttempt(
      attemptId: '', // assigned by Firestore
      userId: userId,
      mode: 'timed',
      submittedAt: DateTime.now(),
      timeLimitSeconds: timeLimitSeconds,
      timeSpentSeconds: result.durationSeconds,
      wasAutoSubmitted: result.wasAutoSubmitted,
      totalQuestions: result.totalQuestions,
      answeredCount: result.answeredCount,
      correctCount: result.correctCount,
      incorrectCount: result.incorrectCount,
      unansweredCount: result.unansweredCount,
      scorePercent: result.scorePercent,
      strongestSubject: breakdown.strongest?.subjectName,
      weakestSubject: breakdown.weakest?.subjectName,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mode': mode,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'timeLimitSeconds': timeLimitSeconds,
      'timeSpentSeconds': timeSpentSeconds,
      'wasAutoSubmitted': wasAutoSubmitted,
      'totalQuestions': totalQuestions,
      'answeredCount': answeredCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'unansweredCount': unansweredCount,
      'scorePercent': scorePercent,
      'strongestSubject': strongestSubject,
      'weakestSubject': weakestSubject,
    };
  }

  factory SavedExamAttempt.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return SavedExamAttempt(
      attemptId: docId,
      userId: data['userId'] as String? ?? '',
      mode: data['mode'] as String? ?? 'timed',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeLimitSeconds: data['timeLimitSeconds'] as int? ?? 0,
      timeSpentSeconds: data['timeSpentSeconds'] as int? ?? 0,
      wasAutoSubmitted: data['wasAutoSubmitted'] as bool? ?? false,
      totalQuestions: data['totalQuestions'] as int? ?? 0,
      answeredCount: data['answeredCount'] as int? ?? 0,
      correctCount: data['correctCount'] as int? ?? 0,
      incorrectCount: data['incorrectCount'] as int? ?? 0,
      unansweredCount: data['unansweredCount'] as int? ?? 0,
      scorePercent: (data['scorePercent'] as num?)?.toDouble() ?? 0.0,
      strongestSubject: data['strongestSubject'] as String?,
      weakestSubject: data['weakestSubject'] as String?,
    );
  }
}
