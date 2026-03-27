class Question {
  const Question({
    required this.questionId,
    required this.subjectId,
    required this.subjectName,
    required this.subtopicId,
    required this.subtopicName,
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
    this.conceptCluster,
    this.difficulty = 'Medium',
    this.questionType,
    this.studyNote,
    this.weaknessLabel,
    this.recommendationText,
    this.sourceType,
    this.sourceReference,
    this.confidenceLevel,
    this.needsManualReview = false,
    this.status = 'Draft',
  });

  final String questionId;
  final String subjectId;
  final String subjectName;
  final String subtopicId;
  final String subtopicName;
  final String questionText;
  final Map<String, String> choices; // {'A': '...', 'B': '...', ...}
  final String correctAnswer; // 'A', 'B', 'C', or 'D'
  final String explanation;
  final String? conceptCluster;
  final String difficulty;
  final String? questionType;
  final String? studyNote;
  final String? weaknessLabel;
  final String? recommendationText;
  final String? sourceType;
  final String? sourceReference;
  final String? confidenceLevel;
  final bool needsManualReview;
  final String status;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      subtopicId: json['subtopicId'] as String,
      subtopicName: json['subtopicName'] as String,
      questionText: json['questionText'] as String,
      choices: {
        'A': json['choiceA'] as String,
        'B': json['choiceB'] as String,
        'C': json['choiceC'] as String,
        'D': json['choiceD'] as String,
      },
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String,
      conceptCluster: json['conceptCluster'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      questionType: json['questionType'] as String?,
      studyNote: json['studyNote'] as String?,
      weaknessLabel: json['weaknessLabel'] as String?,
      recommendationText: json['recommendationText'] as String?,
      sourceType: json['sourceType'] as String?,
      sourceReference: json['sourceReference'] as String?,
      confidenceLevel: json['confidenceLevel'] as String?,
      needsManualReview: json['needsManualReview'] as bool? ?? false,
      status: json['status'] as String? ?? 'Draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subtopicId': subtopicId,
      'subtopicName': subtopicName,
      'questionText': questionText,
      'choiceA': choices['A'],
      'choiceB': choices['B'],
      'choiceC': choices['C'],
      'choiceD': choices['D'],
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'conceptCluster': conceptCluster,
      'difficulty': difficulty,
      'questionType': questionType,
      'studyNote': studyNote,
      'weaknessLabel': weaknessLabel,
      'recommendationText': recommendationText,
      'sourceType': sourceType,
      'sourceReference': sourceReference,
      'confidenceLevel': confidenceLevel,
      'needsManualReview': needsManualReview,
      'status': status,
    };
  }
}
