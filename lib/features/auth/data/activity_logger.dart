import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/activity_log.dart';

/// Fire-and-forget activity logger.
///
/// Writes to `users/{uid}/activityLogs/{auto-id}`.
/// All methods are safe to call without awaiting —
/// failures are logged but never propagate to the caller.
class ActivityLogger {
  ActivityLogger({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('activityLogs');

  /// Logs a single activity event.
  Future<void> log({
    required String uid,
    required String type,
    String? screen,
    String? subjectId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final entry = ActivityLog(
        type: type,
        screen: screen,
        subjectId: subjectId,
        metadata: metadata,
      );
      await _logsRef(uid).add(entry.toFirestore());
      debugPrint('[ActivityLogger] Logged: $type');
    } catch (e) {
      debugPrint('[ActivityLogger] Failed to log $type: $e');
    }
  }
}
