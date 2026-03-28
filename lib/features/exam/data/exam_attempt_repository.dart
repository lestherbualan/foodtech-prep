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
}
