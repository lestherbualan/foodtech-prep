/// Summary produced after an exam session is completed.
class ExamResult {
  const ExamResult({
    required this.sessionId,
    required this.userId,
    required this.totalQuestions,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    this.subjectBreakdown = const {},
    this.completedAt,
  });

  final String sessionId;
  final String userId;
  final int totalQuestions;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;

  /// Per-subject scores: subjectId → {correct, total}
  final Map<String, SubjectScore> subjectBreakdown;
  final DateTime? completedAt;

  double get scorePercent =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'unansweredCount': unansweredCount,
      'subjectBreakdown': subjectBreakdown.map(
        (key, v) => MapEntry(key, v.toJson()),
      ),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctCount: json['correctCount'] as int,
      incorrectCount: json['incorrectCount'] as int,
      unansweredCount: json['unansweredCount'] as int,
      subjectBreakdown:
          (json['subjectBreakdown'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              SubjectScore.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          const {},
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class SubjectScore {
  const SubjectScore({
    required this.subjectName,
    required this.correct,
    required this.total,
  });

  final String subjectName;
  final int correct;
  final int total;

  double get percent => total > 0 ? (correct / total) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {'subjectName': subjectName, 'correct': correct, 'total': total};
  }

  factory SubjectScore.fromJson(Map<String, dynamic> json) {
    return SubjectScore(
      subjectName: json['subjectName'] as String,
      correct: json['correct'] as int,
      total: json['total'] as int,
    );
  }
}
