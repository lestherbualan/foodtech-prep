import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_review_persistence.dart';
import '../../data/admin_review_resume_payload.dart';
import '../../data/choice_randomizer.dart';
import '../../domain/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Session model (in-memory only — never persisted directly)
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory admin review session for a single subtopic.
///
/// This object is never serialised to disk. Persistence is handled separately
/// by [AdminReviewResumePayload], which stores only lightweight IDs and state.
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
  /// Empty when the session was hydrated from a disk payload but not yet
  /// matched against the live question bank (i.e. a skeleton session).
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
  ///
  /// Also returns true for skeleton sessions loaded from disk so that the
  /// Resume button stays visible after app restart.
  bool get hasProgress =>
      selectedAnswers.values.any((v) => v != null) ||
      checkedQuestions.values.any((v) => v) ||
      questions.isEmpty; // skeleton sessions always appear resumable

  // ── Factories ────────────────────────────────────────────────────────────────

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

  /// Creates a skeleton session from a persisted payload.
  ///
  /// The [questions] list is intentionally empty — this signals that the
  /// session needs to be reconstructed from the live question bank before
  /// the player can be launched.  All answer/checked state is preserved so
  /// [hasProgress] returns true and the Resume button remains visible.
  factory AdminReviewSession.fromPayloadSkeleton(
    AdminReviewResumePayload payload,
  ) {
    return AdminReviewSession(
      questions: const [],
      currentIndex: payload.currentIndex,
      selectedAnswers: Map<String, String?>.from(payload.selectedAnswers),
      checkedQuestions: Map<String, bool>.from(payload.checkedQuestions),
      choiceOrders: Map<String, List<int>>.from(payload.choiceOrders),
      displayCorrectAnswers: Map<String, String>.from(
        payload.displayCorrectAnswers,
      ),
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

  // ── Payload conversion ───────────────────────────────────────────────────────

  /// Converts this session to a lightweight [AdminReviewResumePayload] for
  /// disk persistence.  Requires a non-empty [questions] list.
  AdminReviewResumePayload toResumePayload({
    required String sessionKey,
    required String subjectId,
    required String subtopicId,
    String? mode,
  }) {
    return AdminReviewResumePayload(
      sessionKey: sessionKey,
      subjectId: subjectId,
      subtopicId: subtopicId,
      questionIdsInOrder: questions.map((q) => q.questionId).toList(),
      currentIndex: currentIndex,
      selectedAnswers: selectedAnswers,
      checkedQuestions: checkedQuestions,
      displayCorrectAnswers: displayCorrectAnswers,
      choiceOrders: choiceOrders,
      mode: mode,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Reconstructs a full session from a [payload] and the currently available
  /// [availableQuestions] for the subtopic.
  ///
  /// Returns `null` if reconstruction is not possible (empty result or more
  /// than 50 % of the saved question IDs are missing from the current bank).
  static AdminReviewSession? fromResumePayload(
    AdminReviewResumePayload payload,
    List<Question> availableQuestions,
  ) {
    if (payload.questionIdsInOrder.isEmpty) return null;

    final byId = {for (final q in availableQuestions) q.questionId: q};
    final ordered = <Question>[];
    for (final id in payload.questionIdsInOrder) {
      final q = byId[id];
      if (q != null) ordered.add(q);
    }

    if (ordered.isEmpty) return null;

    final missing = payload.questionIdsInOrder.length - ordered.length;
    final missingRatio = missing / payload.questionIdsInOrder.length;
    if (missingRatio > 0.5) return null; // stale session — discard

    final clampedIndex = payload.currentIndex.clamp(0, ordered.length - 1);

    return AdminReviewSession(
      questions: ordered,
      currentIndex: clampedIndex,
      selectedAnswers: Map<String, String?>.from(payload.selectedAnswers),
      checkedQuestions: Map<String, bool>.from(payload.checkedQuestions),
      choiceOrders: Map<String, List<int>>.from(payload.choiceOrders),
      displayCorrectAnswers: Map<String, String>.from(
        payload.displayCorrectAnswers,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AdminReviewSessionNotifier
    extends StateNotifier<Map<String, AdminReviewSession>> {
  AdminReviewSessionNotifier() : super(const {}) {
    _loadFromDisk();
  }

  /// Lightweight payloads loaded from disk, keyed by sessionKey.
  /// Used to reconstruct full sessions on Resume after app restart.
  final Map<String, AdminReviewResumePayload> _loadedPayloads = {};

  // ── Disk hydration ────────────────────────────────────────────────────────────

  /// Reads all stored lightweight payloads from [SharedPreferences] and
  /// hydrates the state with skeleton sessions.
  ///
  /// Skeleton sessions have [AdminReviewSession.questions] == [] but carry
  /// the persisted answer/checked state so [hasProgress] returns true and
  /// the Resume button remains visible.  Full reconstruction happens lazily
  /// via [resolveForResume] when the user actually taps Resume.
  Future<void> _loadFromDisk() async {
    final stored = await AdminReviewPersistence.readAll();
    if (stored.isEmpty) return;

    final sessions = <String, AdminReviewSession>{};
    for (final entry in stored.entries) {
      try {
        final payload = AdminReviewResumePayload.fromJson(entry.value);
        _loadedPayloads[entry.key] = payload;
        sessions[entry.key] = AdminReviewSession.fromPayloadSkeleton(payload);
      } catch (e) {
        debugPrint(
          '[AdminReview] Corrupt session for "${entry.key}", removing: $e',
        );
        await AdminReviewPersistence.delete(entry.key);
      }
    }
    if (sessions.isNotEmpty) state = {...state, ...sessions};
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Saves the session in memory and persists a lightweight payload to disk.
  ///
  /// [session.questions] must be non-empty — skeleton sessions are never
  /// written back to disk.
  void save(String key, AdminReviewSession session) {
    state = {...state, key: session};

    if (session.questions.isEmpty) return; // never persist skeleton

    final firstQ = session.questions.first;
    final payload = session.toResumePayload(
      sessionKey: key,
      subjectId: firstQ.subjectId,
      subtopicId: firstQ.subtopicId,
    );
    _loadedPayloads[key] = payload;
    // Fire-and-forget — in-memory state is already updated.
    AdminReviewPersistence.write(key, payload.toJson());
  }

  AdminReviewSession? load(String key) => state[key];

  bool hasSession(String key) => state.containsKey(key);

  void clear(String key) {
    _loadedPayloads.remove(key);
    final updated = Map<String, AdminReviewSession>.from(state);
    updated.remove(key);
    state = updated;
    AdminReviewPersistence.delete(key);
  }

  // ── Resume reconstruction ─────────────────────────────────────────────────────

  /// Returns a fully populated [AdminReviewSession] ready for the player.
  ///
  /// - If an in-memory session with questions already exists, returns it.
  /// - If a skeleton (disk-loaded) session exists, reconstructs the full
  ///   session from [availableQuestions] and caches the result in state.
  /// - Returns `null` if the session is stale, unresolvable, or does not exist.
  AdminReviewSession? resolveForResume(
    String key,
    List<Question> availableQuestions,
  ) {
    final existing = state[key];
    if (existing == null) return null;

    // Already a full in-memory session — use directly.
    if (existing.questions.isNotEmpty) return existing;

    // Skeleton — attempt reconstruction from the loaded payload.
    final payload = _loadedPayloads[key];
    if (payload == null) return null;

    final reconstructed = AdminReviewSession.fromResumePayload(
      payload,
      availableQuestions,
    );

    if (reconstructed == null) {
      // Stale session — discard.
      clear(key);
      return null;
    }

    // Cache the reconstructed session so subsequent reads are instant.
    state = {...state, key: reconstructed};
    return reconstructed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Keeps admin review sessions in memory across navigation.
///
/// NOT autoDispose — sessions persist for the lifetime of the app so that
/// Resume works correctly after navigating back to the subtopic list.
final adminReviewSessionStoreProvider =
    StateNotifierProvider<
      AdminReviewSessionNotifier,
      Map<String, AdminReviewSession>
    >((ref) => AdminReviewSessionNotifier());
