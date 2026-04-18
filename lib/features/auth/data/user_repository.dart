import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/user_roles.dart';
import '../domain/user_profile.dart';

/// Firestore-backed repository for the `users/{uid}` document.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Creates or updates the user document after sign-in.
  ///
  /// Uses `set` with `merge: true` so existing app-owned fields
  /// (stats, preferences, etc.) are never overwritten.
  /// The `createdAt` field is only set on the very first write.
  Future<void> syncUserProfile(User firebaseUser) async {
    final uid = firebaseUser.uid;
    final doc = _userDoc(uid);

    // Determine the primary provider.
    final providerData = firebaseUser.providerData;
    final primaryProvider = providerData.isNotEmpty
        ? providerData.first.providerId
        : null;
    final providerIds = providerData.map((info) => info.providerId).toList();

    // Check if user doc already exists to decide on createdAt.
    final snapshot = await doc.get();
    final isNewUser = !snapshot.exists;

    final profile = UserProfile(
      uid: uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      photoURL: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      emailVerified: firebaseUser.emailVerified,
      isAnonymous: firebaseUser.isAnonymous,
      provider: primaryProvider,
      providers: providerIds,
    );

    await doc.set(
      profile.toFirestore(isNewUser: isNewUser),
      SetOptions(merge: true),
    );

    debugPrint(
      '[UserRepo] Synced profile for $uid '
      '(${isNewUser ? "new" : "existing"} user)',
    );
  }

  /// Reads the current user profile from Firestore.
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfile.fromFirestore(snapshot.data()!);
    } catch (e) {
      debugPrint('[UserRepo] Failed to read profile for $uid: $e');
      return null;
    }
  }

  /// Touches `lastActiveAt` with a server timestamp.
  Future<void> updateLastActive(String uid) async {
    try {
      await _userDoc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[UserRepo] Failed to update lastActiveAt: $e');
    }
  }

  /// Incremental stats update after an exam attempt.
  ///
  /// Reads the current stats, recalculates, and writes back.
  Future<void> updateStatsAfterExam({
    required String uid,
    required double scorePercent,
    required String? strongestSubject,
    required String? weakestSubject,
  }) async {
    try {
      final snapshot = await _userDoc(uid).get();
      final data = snapshot.data();
      final existing = data != null && data['stats'] is Map<String, dynamic>
          ? UserStats.fromMap(data['stats'] as Map<String, dynamic>)
          : const UserStats();

      final newTotal = existing.totalExamsTaken + 1;
      final newBest = scorePercent > existing.bestScore
          ? scorePercent
          : existing.bestScore;
      // Running average
      final newAvg =
          ((existing.averageScore * existing.totalExamsTaken) + scorePercent) /
          newTotal;

      final updatedStats = UserStats(
        totalExamsTaken: newTotal,
        bestScore: newBest,
        averageScore: double.parse(newAvg.toStringAsFixed(2)),
        latestScore: scorePercent,
        strongestSubject: strongestSubject ?? existing.strongestSubject,
        weakestSubject: weakestSubject ?? existing.weakestSubject,
      );

      await _userDoc(
        uid,
      ).set({'stats': updatedStats.toMap()}, SetOptions(merge: true));

      debugPrint(
        '[UserRepo] Updated stats for $uid — '
        'total: $newTotal, best: $newBest, avg: ${updatedStats.averageScore}',
      );
    } catch (e) {
      debugPrint('[UserRepo] Failed to update stats: $e');
    }
  }

  // ── Admin management ──────────────────────────────────────────────────────

  /// Updates a user's role and derived permissions.
  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      final permissions = UserPermissions.fromRole(role);
      await _userDoc(uid).set({
        'role': role.value,
        'permissions': permissions.toMap(),
      }, SetOptions(merge: true));

      debugPrint('[UserRepo] Updated role for $uid to ${role.value}');
    } catch (e) {
      debugPrint('[UserRepo] Failed to update role: $e');
      rethrow;
    }
  }

  /// Searches users by email prefix (Firestore range query).
  Future<List<UserProfile>> searchUsersByEmail(String emailQuery) async {
    try {
      if (emailQuery.isEmpty) return const [];

      final query = emailQuery.toLowerCase().trim();
      final snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => UserProfile.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[UserRepo] Failed to search users by email: $e');
      return const [];
    }
  }

  /// Searches users by display name prefix (Firestore range query).
  Future<List<UserProfile>> searchUsersByDisplayName(String nameQuery) async {
    try {
      if (nameQuery.isEmpty) return const [];

      final query = nameQuery.trim();
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => UserProfile.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[UserRepo] Failed to search users by name: $e');
      return const [];
    }
  }

  /// Searches users by email or display name and merges results.
  /// Uses client-side case-insensitive filtering for reliable matching.
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return const [];

    final lowerQuery = query.trim().toLowerCase();

    try {
      final snapshot = await _firestore.collection('users').limit(200).get();

      debugPrint(
        '[UserRepo] searchUsers: fetched ${snapshot.docs.length} user docs',
      );

      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => UserProfile.fromFirestore(doc.data()))
          .where((profile) {
            final name = (profile.displayName ?? '').toLowerCase();
            final email = (profile.email ?? '').toLowerCase();
            return name.contains(lowerQuery) || email.contains(lowerQuery);
          })
          .toList();
    } catch (e) {
      debugPrint('[UserRepo] Failed to search users: $e');
      rethrow;
    }
  }

  /// Loads all users with a privileged role (super_admin or question_admin).
  Future<List<UserProfile>> getPrivilegedUsers() async {
    try {
      final results = <UserProfile>[];

      for (final role in [UserRole.superAdmin, UserRole.questionAdmin]) {
        final snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: role.value)
            .get();

        for (final doc in snapshot.docs) {
          if (doc.data().isNotEmpty) {
            results.add(UserProfile.fromFirestore(doc.data()));
          }
        }
      }

      debugPrint(
        '[UserRepo] getPrivilegedUsers: found ${results.length} users',
      );
      return results;
    } catch (e) {
      debugPrint('[UserRepo] Failed to load privileged users: $e');
      rethrow;
    }
  }

  /// Persists FCM notification token and permission state into the user doc.
  ///
  /// Uses merge semantics so existing profile fields are never overwritten.
  Future<void> updateNotificationToken({
    required String uid,
    required String? token,
    required bool notificationsEnabled,
    required String permissionStatus,
  }) async {
    try {
      await _userDoc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': notificationsEnabled,
        'notificationPermissionStatus': permissionStatus,
      }, SetOptions(merge: true));

      debugPrint(
        '[UserRepo] Saved notification token for $uid '
        '(enabled: $notificationsEnabled, status: $permissionStatus)',
      );
    } catch (e) {
      debugPrint('[UserRepo] Failed to save notification token for $uid: $e');
    }
  }
}
