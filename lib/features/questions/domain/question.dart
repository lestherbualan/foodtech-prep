import '../../../core/constants/question_types.dart';

/// A single answer option for a question.
class QuestionOption {
  const QuestionOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  final String optionId;
  final String text;
  final bool isCorrect;
}

class Question {
  const Question({
    required this.questionId,
    required this.subjectId,
    required this.subjectName,
    required this.subtopicId,
    required this.subtopicName,
    required this.questionText,
    required this.options,
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
  final List<QuestionOption> options;
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

  /// Index of the correct option in the options list (-1 if none).
  int get correctOptionIndex => options.indexWhere((o) => o.isCorrect);

  /// Display label for the correct answer in natural (unshuffled) order.
  static const _labels = ['A', 'B', 'C', 'D'];
  String get correctAnswerLabel {
    final idx = correctOptionIndex;
    if (idx < 0 || idx >= _labels.length) return 'A';
    return _labels[idx];
  }

  /// Serialises the question to Firestore v2 format (options array).
  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subtopicId': subtopicId,
      'subtopicName': subtopicName,
      'questionText': questionText,
      'options': options
          .map(
            (o) => {
              'optionId': o.optionId,
              'text': o.text,
              'isCorrect': o.isCorrect,
            },
          )
          .toList(),
      'explanation': explanation,
      if (conceptCluster != null) 'conceptCluster': conceptCluster,
      'difficulty': difficulty,
      if (questionType != null) 'questionType': questionType,
      if (studyNote != null) 'studyNote': studyNote,
      if (weaknessLabel != null) 'weaknessLabel': weaknessLabel,
      if (recommendationText != null) 'recommendationText': recommendationText,
      if (sourceType != null) 'sourceType': sourceType,
      if (sourceFile != null) 'sourceFile': sourceFile,
      if (sourceReference != null) 'sourceReference': sourceReference,
      if (confidenceLevel != null) 'confidenceLevel': confidenceLevel,
      'needsManualReview': needsManualReview,
      'isOfficiallyVerified': isOfficiallyVerified,
      'status': status,
      if (createdBy != null) 'createdBy': createdBy,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (version != null) 'version': version,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
    };
  }

  /// Creates a copy with the given fields replaced.
  Question copyWith({
    String? questionText,
    List<QuestionOption>? options,
    String? explanation,
    String? difficulty,
    String? questionType,
    String? studyNote,
    String? weaknessLabel,
    String? recommendationText,
    String? sourceReference,
    String? status,
    String? reviewedBy,
    String? lastUpdated,
  }) {
    return Question(
      questionId: questionId,
      subjectId: subjectId,
      subjectName: subjectName,
      subtopicId: subtopicId,
      subtopicName: subtopicName,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      explanation: explanation ?? this.explanation,
      conceptCluster: conceptCluster,
      difficulty: difficulty ?? this.difficulty,
      questionType: questionType ?? this.questionType,
      studyNote: studyNote ?? this.studyNote,
      weaknessLabel: weaknessLabel ?? this.weaknessLabel,
      recommendationText: recommendationText ?? this.recommendationText,
      sourceType: sourceType,
      sourceFile: sourceFile,
      sourceReference: sourceReference ?? this.sourceReference,
      confidenceLevel: confidenceLevel,
      needsManualReview: needsManualReview,
      isOfficiallyVerified: isOfficiallyVerified,
      status: status ?? this.status,
      createdBy: createdBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      version: version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Parses v1 local JSON (choiceA/B/C/D + correctAnswer).
  factory Question.fromJson(Map<String, dynamic> json) {
    final String correctLetter = json['correctAnswer'] as String;
    return Question(
      questionId: json['questionId'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      subtopicId: json['subtopicId'] as String,
      subtopicName: json['subtopicName'] as String,
      questionText: json['questionText'] as String,
      options: [
        QuestionOption(
          optionId: 'A',
          text: json['choiceA'] as String,
          isCorrect: correctLetter == 'A',
        ),
        QuestionOption(
          optionId: 'B',
          text: json['choiceB'] as String,
          isCorrect: correctLetter == 'B',
        ),
        QuestionOption(
          optionId: 'C',
          text: json['choiceC'] as String,
          isCorrect: correctLetter == 'C',
        ),
        QuestionOption(
          optionId: 'D',
          text: json['choiceD'] as String,
          isCorrect: correctLetter == 'D',
        ),
      ],
      explanation: json['explanation'] as String,
      conceptCluster: json['conceptCluster'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      questionType: QuestionTypes.normalizeQuestionType(
        json['questionType'] as String?,
      ),
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

  /// Parses a Firestore question document (v2 schema with options[],
  /// falls back to v1 flat choiceA-D if options is absent).
  factory Question.fromFirestore(String docId, Map<String, dynamic> data) {
    final rawOptions = data['options'] as List<dynamic>?;
    final List<QuestionOption> options;

    if (rawOptions != null && rawOptions.isNotEmpty) {
      // v2 schema
      options = rawOptions.map((o) {
        final m = o as Map<String, dynamic>;
        return QuestionOption(
          optionId: m['optionId'] as String? ?? '',
          text: m['text'] as String? ?? '',
          isCorrect: m['isCorrect'] as bool? ?? false,
        );
      }).toList();
    } else {
      // v1 fallback
      final correctLetter = data['correctAnswer'] as String? ?? '';
      options = [
        QuestionOption(
          optionId: 'A',
          text: data['choiceA'] as String? ?? '',
          isCorrect: correctLetter == 'A',
        ),
        QuestionOption(
          optionId: 'B',
          text: data['choiceB'] as String? ?? '',
          isCorrect: correctLetter == 'B',
        ),
        QuestionOption(
          optionId: 'C',
          text: data['choiceC'] as String? ?? '',
          isCorrect: correctLetter == 'C',
        ),
        QuestionOption(
          optionId: 'D',
          text: data['choiceD'] as String? ?? '',
          isCorrect: correctLetter == 'D',
        ),
      ];
    }

    return Question(
      questionId: data['questionId'] as String? ?? docId,
      subjectId: data['subjectId'] as String? ?? '',
      subjectName: data['subjectName'] as String? ?? '',
      subtopicId: data['subtopicId'] as String? ?? '',
      subtopicName: data['subtopicName'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      options: options,
      explanation: data['explanation'] as String? ?? '',
      conceptCluster: data['conceptCluster'] as String?,
      difficulty: data['difficulty'] as String? ?? 'Medium',
      questionType: QuestionTypes.normalizeQuestionType(
        data['questionType'] as String?,
      ),
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
}
