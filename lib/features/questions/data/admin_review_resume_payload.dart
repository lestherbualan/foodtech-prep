// ─────────────────────────────────────────────────────────────────────────────
// Lightweight Resume Payload — persisted to SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal data stored to disk so that Resume survives app close/reopen.
///
/// Contains only IDs and interaction state — never full [Question] objects.
/// Full questions are reconstructed at restore time from the currently loaded
/// question bank.
class AdminReviewResumePayload {
  const AdminReviewResumePayload({
    required this.sessionKey,
    required this.subjectId,
    required this.subtopicId,
    required this.questionIdsInOrder,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.checkedQuestions,
    required this.displayCorrectAnswers,
    required this.choiceOrders,
    this.mode,
    required this.updatedAt,
  });

  /// Stable persistence key: `{subjectId}|{subtopicId}`.
  final String sessionKey;

  /// Firestore subject document ID.
  final String subjectId;

  /// Firestore subtopic document ID.
  final String subtopicId;

  /// Ordered list of question document IDs for the session.
  /// Preserves the original sequential or shuffled order.
  final List<String> questionIdsInOrder;

  /// Last active question position (0-based).
  final int currentIndex;

  /// `questionId → chosen display letter` (A/B/C/D). Null means unanswered.
  final Map<String, String?> selectedAnswers;

  /// `questionId → true` if "Check Answer" was tapped for that question.
  final Map<String, bool> checkedQuestions;

  /// `questionId → display label (A/B/C/D)` of the correct option after
  /// any choice shuffle was applied.
  final Map<String, String> displayCorrectAnswers;

  /// `questionId → shuffled index list` that maps display position to the
  /// original options list index.
  final Map<String, List<int>> choiceOrders;

  /// Optional mode tag: 'sequential', 'shuffled', 'tapped-card', 'resume'.
  final String? mode;

  /// ISO-8601 timestamp of the last save.
  final String updatedAt;

  // ── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'sessionKey': sessionKey,
      'subjectId': subjectId,
      'subtopicId': subtopicId,
      'questionIdsInOrder': questionIdsInOrder,
      'currentIndex': currentIndex,
      'selectedAnswers': selectedAnswers,
      'checkedQuestions': checkedQuestions,
      'displayCorrectAnswers': displayCorrectAnswers,
      'choiceOrders': choiceOrders.map((k, v) => MapEntry(k, v)),
      if (mode != null) 'mode': mode,
      'updatedAt': updatedAt,
    };
  }

  factory AdminReviewResumePayload.fromJson(Map<String, dynamic> json) {
    final selectedAnswers = <String, String?>{};
    (json['selectedAnswers'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      selectedAnswers[k] = v as String?;
    });

    final checkedQuestions = <String, bool>{};
    (json['checkedQuestions'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      checkedQuestions[k] = v as bool;
    });

    final displayCorrectAnswers = <String, String>{};
    (json['displayCorrectAnswers'] as Map<String, dynamic>? ?? {}).forEach(
      (k, v) => displayCorrectAnswers[k] = v as String,
    );

    final choiceOrders = <String, List<int>>{};
    (json['choiceOrders'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      choiceOrders[k] = (v as List<dynamic>)
          .map((i) => (i as num).toInt())
          .toList();
    });

    return AdminReviewResumePayload(
      sessionKey: json['sessionKey'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subtopicId: json['subtopicId'] as String? ?? '',
      questionIdsInOrder: (json['questionIdsInOrder'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      selectedAnswers: selectedAnswers,
      checkedQuestions: checkedQuestions,
      displayCorrectAnswers: displayCorrectAnswers,
      choiceOrders: choiceOrders,
      mode: json['mode'] as String?,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
