import 'exam_answer.dart';

enum ExamMode { practice, timed }

enum ExamStatus { inProgress, completed, abandoned }

/// Represents a single exam-taking session.
class ExamSession {
  const ExamSession({
    required this.sessionId,
    required this.userId,
    required this.questionIds,
    this.mode = ExamMode.practice,
    this.status = ExamStatus.inProgress,
    this.answers = const {},
    this.startedAt,
    this.completedAt,
    this.timeLimitSeconds,
  });

  final String sessionId;
  final String userId;
  final List<String> questionIds;
  final ExamMode mode;
  final ExamStatus status;
  final Map<String, ExamAnswer> answers; // keyed by questionId
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? timeLimitSeconds;

  int get totalQuestions => questionIds.length;
  int get answeredCount => answers.length;
  bool get isComplete => status == ExamStatus.completed;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'questionIds': questionIds,
      'mode': mode.name,
      'status': status.name,
      'answers': answers.map((key, value) => MapEntry(key, value.toJson())),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeLimitSeconds': timeLimitSeconds,
    };
  }

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    return ExamSession(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      questionIds: List<String>.from(json['questionIds'] as List),
      mode: ExamMode.values.byName(json['mode'] as String),
      status: ExamStatus.values.byName(json['status'] as String),
      answers:
          (json['answers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ExamAnswer.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          const {},
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
    );
  }
}
