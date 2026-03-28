/// Metadata for a Firestore question bank.
class QuestionBank {
  const QuestionBank({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.isPublished,
    required this.version,
    required this.questionCount,
    this.sourceType,
  });

  final String id;
  final String title;
  final String description;
  final bool isActive;
  final bool isPublished;
  final String version;
  final int questionCount;
  final String? sourceType;

  factory QuestionBank.fromFirestore(String docId, Map<String, dynamic> data) {
    return QuestionBank(
      id: data['id'] as String? ?? docId,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      isPublished: data['isPublished'] as bool? ?? false,
      version: data['version']?.toString() ?? '1',
      questionCount:
          _safeInt(data['questionCount']) ??
          _safeInt(data['totalQuestions']) ??
          0,
      sourceType: data['sourceType'] as String?,
    );
  }

  static int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
