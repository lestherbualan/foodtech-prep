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
    this.sourceFile,
    this.sourceReference,
    this.confidenceLevel,
    this.needsManualReview = false,
    this.isOfficiallyVerified = false,
    this.status = 'Draft',
    this.createdBy,
    this.reviewedBy,
    this.version,
    this.lastUpdated,
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
  final String? sourceFile;
  final String? sourceReference;
  final String? confidenceLevel;
  final bool needsManualReview;
  final bool isOfficiallyVerified;
  final String status;
  final String? createdBy;
  final String? reviewedBy;
  final String? version;
  final String? lastUpdated;

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
      sourceFile: json['sourceFile'] as String?,
      sourceReference: json['sourceReference'] as String?,
      confidenceLevel: json['confidenceLevel'] as String?,
      needsManualReview: json['needsManualReview'] as bool? ?? false,
      isOfficiallyVerified: json['isOfficiallyVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'Draft',
      createdBy: json['createdBy'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      version: json['version']?.toString(),
      lastUpdated: json['lastUpdated'] as String?,
    );
  }

  /// Maps a Firestore question document into the app model.
  /// Firestore docs use the same flat field structure as local JSON.
  factory Question.fromFirestore(String docId, Map<String, dynamic> data) {
    return Question(
      questionId: data['questionId'] as String? ?? docId,
      subjectId: data['subjectId'] as String? ?? '',
      subjectName: data['subjectName'] as String? ?? '',
      subtopicId: data['subtopicId'] as String? ?? '',
      subtopicName: data['subtopicName'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      choices: {
        'A': data['choiceA'] as String? ?? '',
        'B': data['choiceB'] as String? ?? '',
        'C': data['choiceC'] as String? ?? '',
        'D': data['choiceD'] as String? ?? '',
      },
      correctAnswer: data['correctAnswer'] as String? ?? '',
      explanation: data['explanation'] as String? ?? '',
      conceptCluster: data['conceptCluster'] as String?,
      difficulty: data['difficulty'] as String? ?? 'Medium',
      questionType: data['questionType'] as String?,
      studyNote: data['studyNote'] as String?,
      weaknessLabel: data['weaknessLabel'] as String?,
      recommendationText: data['recommendationText'] as String?,
      sourceType: data['sourceType'] as String?,
      sourceFile: data['sourceFile'] as String?,
      sourceReference: data['sourceReference'] as String?,
      confidenceLevel: data['confidenceLevel'] as String?,
      needsManualReview: data['needsManualReview'] as bool? ?? false,
      isOfficiallyVerified: data['isOfficiallyVerified'] as bool? ?? false,
      status: data['status'] as String? ?? 'Draft',
      createdBy: data['createdBy'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      version: data['version']?.toString(),
      lastUpdated: data['lastUpdated']?.toString(),
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
      'sourceFile': sourceFile,
      'sourceReference': sourceReference,
      'confidenceLevel': confidenceLevel,
      'needsManualReview': needsManualReview,
      'isOfficiallyVerified': isOfficiallyVerified,
      'status': status,
      'createdBy': createdBy,
      'reviewedBy': reviewedBy,
      'version': version,
      'lastUpdated': lastUpdated,
    };
  }
}
