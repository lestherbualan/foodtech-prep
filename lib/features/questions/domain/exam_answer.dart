/// Represents a single answer given by the user during an exam session.
class ExamAnswer {
  const ExamAnswer({
    required this.questionId,
    required this.selectedAnswer,
    this.isCorrect = false,
    this.answeredAt,
  });

  final String questionId;
  final String selectedAnswer; // 'A', 'B', 'C', or 'D'
  final bool isCorrect;
  final DateTime? answeredAt;

  ExamAnswer copyWith({
    String? selectedAnswer,
    bool? isCorrect,
    DateTime? answeredAt,
  }) {
    return ExamAnswer(
      questionId: questionId,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt?.toIso8601String(),
    };
  }

  factory ExamAnswer.fromJson(Map<String, dynamic> json) {
    return ExamAnswer(
      questionId: json['questionId'] as String,
      selectedAnswer: json['selectedAnswer'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
    );
  }
}
