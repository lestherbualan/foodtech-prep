import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/choice_randomizer.dart';
import '../../domain/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Session model
// ─────────────────────────────────────────────────────────────────────────────

/// A persisted admin review session for a single subtopic.
///
/// Keyed by `subtopicName` in [adminReviewSessionStoreProvider].
/// Survives navigation back to the review list, enabling Resume.
class AdminReviewSession {
  const AdminReviewSession({
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.checkedQuestions,
    required this.choiceOrders,
    required this.displayCorrectAnswers,
  });

  /// Questions in the session's preserved order (sequential or shuffled).
  final List<Question> questions;

  /// Current position within the question list.
  final int currentIndex;

  /// `questionId → chosen display letter` (null if not yet answered).
  final Map<String, String?> selectedAnswers;

  /// `questionId → true` once "Check Answer" has been tapped.
  final Map<String, bool> checkedQuestions;

  /// Stable shuffled display order per question.
  final Map<String, List<int>> choiceOrders;

  /// Which display label (A/B/C/D) holds the correct option after shuffle.
  final Map<String, String> displayCorrectAnswers;

  /// True if the user has interacted at all (for Resume badge display).
  bool get hasProgress =>
      selectedAnswers.values.any((v) => v != null) ||
      checkedQuestions.values.any((v) => v);

  // ── Factory ──────────────────────────────────────────────────────────────────

  factory AdminReviewSession.create(
    List<Question> questions,
    int startIndex, {
    int? seed,
  }) {
    final mappings = generateChoiceMappings(questions, seed: seed);
    return AdminReviewSession(
      questions: questions,
      currentIndex: questions.isEmpty
          ? 0
          : startIndex.clamp(0, questions.length - 1),
      selectedAnswers: const {},
      checkedQuestions: const {},
      choiceOrders: mappings.choiceOrders,
      displayCorrectAnswers: mappings.displayCorrectAnswers,
    );
  }

  // ── CopyWith ─────────────────────────────────────────────────────────────────

  AdminReviewSession copyWith({
    int? currentIndex,
    Map<String, String?>? selectedAnswers,
    Map<String, bool>? checkedQuestions,
  }) {
    return AdminReviewSession(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      checkedQuestions: checkedQuestions ?? this.checkedQuestions,
      choiceOrders: choiceOrders,
      displayCorrectAnswers: displayCorrectAnswers,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AdminReviewSessionNotifier
    extends StateNotifier<Map<String, AdminReviewSession>> {
  AdminReviewSessionNotifier() : super(const {});

  void save(String key, AdminReviewSession session) {
    state = {...state, key: session};
  }

  AdminReviewSession? load(String key) => state[key];

  bool hasSession(String key) => state.containsKey(key);

  void clear(String key) {
    final updated = Map<String, AdminReviewSession>.from(state);
    updated.remove(key);
    state = updated;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Keeps admin review sessions in memory across navigation.
///
/// NOT autoDispose — sessions persist for the lifetime of the app so that
/// Resume works correctly.
final adminReviewSessionStoreProvider =
    StateNotifierProvider<
      AdminReviewSessionNotifier,
      Map<String, AdminReviewSession>
    >((ref) => AdminReviewSessionNotifier());
