import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/saved_exam_attempt.dart';

/// Firestore-backed repository for saving and reading exam attempts.
class ExamAttemptRepository {
  ExamAttemptRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns the user's exam attempts collection reference.
  CollectionReference<Map<String, dynamic>> _attemptsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('examAttempts');

  /// Saves an exam attempt. Returns the document ID.
  Future<String> saveAttempt(SavedExamAttempt attempt) async {
    try {
      final docRef = await _attemptsRef(
        attempt.userId,
      ).add(attempt.toFirestore());
      debugPrint('[ExamAttemptRepo] Saved attempt ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[ExamAttemptRepo] Failed to save attempt: $e');
      rethrow;
    }
  }

  /// Loads recent exam attempts for a user, ordered by submission date descending.
  Future<List<SavedExamAttempt>> getRecentAttempts(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _attemptsRef(
        userId,
      ).orderBy('submittedAt', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => SavedExamAttempt.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ExamAttemptRepo] Failed to load attempts: $e');
      rethrow;
    }
  }

  /// Loads all exam attempts for a user within a date range (inclusive).
  ///
  /// [start] and [end] should be midnight-local dates.
  /// Results are ordered by submission date descending.
  Future<List<SavedExamAttempt>> getAttemptsForDateRange(
    String userId, {
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _attemptsRef(userId)
          .where(
            'submittedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'submittedAt',
            isLessThan: Timestamp.fromDate(end.add(const Duration(days: 1))),
          )
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SavedExamAttempt.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ExamAttemptRepo] Failed to load date-range attempts: $e');
      rethrow;
    }
  }
}
