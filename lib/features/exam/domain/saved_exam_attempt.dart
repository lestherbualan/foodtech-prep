import 'package:cloud_firestore/cloud_firestore.dart';

import '../../questions/domain/question.dart';
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
    this.questionIds,
    this.answers,
    this.choiceOrders,
    this.displayCorrectAnswers,
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

  /// Review data — stored for attempts that support question-by-question review.
  final List<String>? questionIds;
  final Map<String, String>? answers;
  final Map<String, List<int>>? choiceOrders;
  final Map<String, String>? displayCorrectAnswers;

  /// Whether this attempt has stored review data.
  bool get hasReviewData => questionIds != null && answers != null;

  /// Reconstructs an [ExamResult] from stored review data and loaded questions.
  /// Returns null if review data is missing or questions can't be matched.
  ExamResult? toExamResult(List<Question> allQuestions) {
    if (questionIds == null || answers == null) return null;

    final questionMap = {for (final q in allQuestions) q.questionId: q};
    final examQuestions = <Question>[];
    for (final id in questionIds!) {
      final q = questionMap[id];
      if (q != null) examQuestions.add(q);
    }

    if (examQuestions.isEmpty) return null;

    return ExamResult.compute(
      questions: examQuestions,
      answers: answers!,
      durationSeconds: timeSpentSeconds,
      wasAutoSubmitted: wasAutoSubmitted,
      timeLimitSeconds: timeLimitSeconds,
      choiceOrders: choiceOrders ?? const {},
      displayCorrectAnswers: displayCorrectAnswers ?? const {},
    );
  }

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
      questionIds: result.questions.map((q) => q.questionId).toList(),
      answers: result.answers,
      choiceOrders: result.choiceOrders,
      displayCorrectAnswers: result.displayCorrectAnswers,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
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
    if (questionIds != null) data['questionIds'] = questionIds;
    if (answers != null) data['answers'] = answers;
    if (choiceOrders != null) {
      data['choiceOrders'] = choiceOrders!.map((k, v) => MapEntry(k, v));
    }
    if (displayCorrectAnswers != null) {
      data['displayCorrectAnswers'] = displayCorrectAnswers;
    }
    return data;
  }

  factory SavedExamAttempt.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    // Parse choiceOrders from Firestore (Map<String, dynamic> → Map<String, List<int>>).
    Map<String, List<int>>? choiceOrders;
    if (data['choiceOrders'] is Map) {
      choiceOrders = (data['choiceOrders'] as Map).map(
        (k, v) => MapEntry(
          k as String,
          (v as List).map((e) => (e as num).toInt()).toList(),
        ),
      );
    }

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
      questionIds: (data['questionIds'] as List?)?.cast<String>(),
      answers: (data['answers'] as Map?)?.cast<String, String>(),
      choiceOrders: choiceOrders,
      displayCorrectAnswers: (data['displayCorrectAnswers'] as Map?)
          ?.cast<String, String>(),
    );
  }
}
