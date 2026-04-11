import 'package:cloud_firestore/cloud_firestore.dart';

/// A single user-activity event stored at `users/{uid}/activityLogs/{docId}`.
class ActivityLog {
  const ActivityLog({
    required this.type,
    this.screen,
    this.subjectId,
    this.metadata = const {},
    this.timestamp,
  });

  /// Event type, e.g. `app_open`, `login`, `start_timed_exam`.
  final String type;

  /// Screen name where the event occurred, if relevant.
  final String? screen;

  /// Subject ID if the event is subject-specific.
  final String? subjectId;

  /// Open-ended key/value pairs for future analytics
  /// (e.g. `{'examCount': 60, 'score': 85.0}`).
  final Map<String, dynamic> metadata;

  /// Event timestamp (assigned server-side when null).
  final DateTime? timestamp;

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      if (screen != null) 'screen': screen,
      if (subjectId != null) 'subjectId': subjectId,
      if (metadata.isNotEmpty) 'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory ActivityLog.fromFirestore(String docId, Map<String, dynamic> data) {
    return ActivityLog(
      type: data['type'] as String? ?? '',
      screen: data['screen'] as String?,
      subjectId: data['subjectId'] as String?,
      metadata: data['metadata'] is Map<String, dynamic>
          ? data['metadata'] as Map<String, dynamic>
          : const {},
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

/// Predefined activity event types.
///
/// Use these constants instead of raw strings to prevent typos.
abstract class ActivityType {
  static const appOpen = 'app_open';
  static const login = 'login';
  static const logout = 'logout';
  static const startTimedExam = 'start_timed_exam';
  static const submitTimedExam = 'submit_timed_exam';
  static const openSubjectPractice = 'open_subject_practice';
  static const openWeakAreas = 'open_weak_areas';
  static const openProgress = 'open_progress';
  static const openQuestionBank = 'open_question_bank';
  static const selectSubjectFocus = 'select_subject_focus';
  static const openProfile = 'open_profile';
  // Future event types – add as features ship:
  // static const flashcardSessionStart = 'flashcard_session_start';
  // static const flashcardSessionComplete = 'flashcard_session_complete';
}
