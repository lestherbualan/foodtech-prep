import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/user_roles.dart';

/// Firestore-persisted user profile at `users/{uid}`.
///
/// Contains auth-derived fields, app-owned stats, role/permissions,
/// and future-ready maps for preferences/activity/study summaries.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.phoneNumber,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.provider,
    this.providers = const [],
    this.createdAt,
    this.lastLoginAt,
    this.lastActiveAt,
    this.role = UserRole.user,
    this.permissions = const UserPermissions(),
    this.stats = const UserStats(),
    this.preferences = const {},
    this.activitySummary = const {},
    this.studySummary = const {},
  });

  // ── Auth-derived fields ──
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? phoneNumber;
  final bool emailVerified;
  final bool isAnonymous;
  final String? provider;
  final List<String> providers;

  // ── Timestamps ──
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;

  // ── Role & permissions ──
  final UserRole role;
  final UserPermissions permissions;

  // ── App-owned summary data ──
  final UserStats stats;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> activitySummary;
  final Map<String, dynamic> studySummary;

  /// Whether this user has any elevated privileges.
  bool get isPrivileged =>
      role == UserRole.superAdmin || role == UserRole.questionAdmin;

  /// Serialises for Firestore writes.
  ///
  /// Uses [FieldValue.serverTimestamp] for timestamp fields when appropriate.
  Map<String, dynamic> toFirestore({bool isNewUser = false}) {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'isAnonymous': isAnonymous,
      'provider': provider,
      'providers': providers,
      if (isNewUser) 'createdAt': FieldValue.serverTimestamp(),
      if (isNewUser) 'role': role.value,
      if (isNewUser) 'permissions': permissions.toMap(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'stats': stats.toMap(),
      'preferences': preferences,
      'activitySummary': activitySummary,
      'studySummary': studySummary,
    };
  }

  /// Constructs from a Firestore document snapshot.
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    final role = UserRole.fromString(data['role'] as String? ?? 'user');
    // Derive permissions from role. If explicit permissions are stored
    // in the doc they are ignored in favour of the role-derived set,
    // ensuring a single source of truth.
    final permissions = UserPermissions.fromRole(role);

    return UserProfile(
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      provider: data['provider'] as String?,
      providers: _stringList(data['providers']),
      createdAt: _toDateTime(data['createdAt']),
      lastLoginAt: _toDateTime(data['lastLoginAt']),
      lastActiveAt: _toDateTime(data['lastActiveAt']),
      role: role,
      permissions: permissions,
      stats: data['stats'] is Map<String, dynamic>
          ? UserStats.fromMap(data['stats'] as Map<String, dynamic>)
          : const UserStats(),
      preferences: _safeMap(data['preferences']),
      activitySummary: _safeMap(data['activitySummary']),
      studySummary: _safeMap(data['studySummary']),
    );
  }

  // ── Helpers ──
  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return const [];
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return const {};
  }
}

/// App-owned aggregate stats stored inside the user document.
class UserStats {
  const UserStats({
    this.totalExamsTaken = 0,
    this.bestScore = 0.0,
    this.averageScore = 0.0,
    this.latestScore = 0.0,
    this.strongestSubject,
    this.weakestSubject,
  });

  final int totalExamsTaken;
  final double bestScore;
  final double averageScore;
  final double latestScore;
  final String? strongestSubject;
  final String? weakestSubject;

  Map<String, dynamic> toMap() {
    return {
      'totalExamsTaken': totalExamsTaken,
      'bestScore': bestScore,
      'averageScore': averageScore,
      'latestScore': latestScore,
      'strongestSubject': strongestSubject,
      'weakestSubject': weakestSubject,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      totalExamsTaken: data['totalExamsTaken'] as int? ?? 0,
      bestScore: (data['bestScore'] as num?)?.toDouble() ?? 0.0,
      averageScore: (data['averageScore'] as num?)?.toDouble() ?? 0.0,
      latestScore: (data['latestScore'] as num?)?.toDouble() ?? 0.0,
      strongestSubject: data['strongestSubject'] as String?,
      weakestSubject: data['weakestSubject'] as String?,
    );
  }
}
