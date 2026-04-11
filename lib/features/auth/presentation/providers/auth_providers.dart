import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/user_roles.dart';
import '../../data/activity_logger.dart';
import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';
import '../../domain/activity_log.dart';
import '../../domain/user_profile.dart';

// ---------------------------------------------------------------------------
// Firebase Auth instance
// ---------------------------------------------------------------------------
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// ---------------------------------------------------------------------------
// Google Sign-In instance
// ---------------------------------------------------------------------------
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

// ---------------------------------------------------------------------------
// Auth repository
// ---------------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

// ---------------------------------------------------------------------------
// User repository (Firestore user documents)
// ---------------------------------------------------------------------------
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// ---------------------------------------------------------------------------
// Activity logger (Firestore activity logs)
// ---------------------------------------------------------------------------
final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger();
});

// ---------------------------------------------------------------------------
// Auth state stream (drives router redirects)
// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Current user profile from Firestore (lazy, refreshable)
// ---------------------------------------------------------------------------
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  return ref.watch(userRepositoryProvider).getProfile(user.uid);
});

// ---------------------------------------------------------------------------
// Auth action notifier (Google sign-in / sign-out)
// ---------------------------------------------------------------------------
class AuthActionNotifier extends StateNotifier<AsyncValue<void>> {
  AuthActionNotifier(this._repository, this._userRepo, this._activityLogger)
    : super(const AsyncData(null));

  final AuthRepository _repository;
  final UserRepository _userRepo;
  final ActivityLogger _activityLogger;

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _repository.signInWithGoogle();
      final user = credential.user;
      if (user != null) {
        // Sync profile to Firestore (create or merge).
        await _userRepo.syncUserProfile(user);
        // Log the sign-in event.
        _activityLogger.log(
          uid: user.uid,
          type: ActivityType.login,
          metadata: {'method': 'google'},
        );
      }
    });
  }

  Future<void> signOut() async {
    // Log before signing out so we still have the uid.
    final uid = _repository.currentUser?.uid;
    if (uid != null) {
      _activityLogger.log(uid: uid, type: ActivityType.logout);
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.signOut());
  }
}

final authActionProvider =
    StateNotifierProvider<AuthActionNotifier, AsyncValue<void>>((ref) {
      return AuthActionNotifier(
        ref.watch(authRepositoryProvider),
        ref.watch(userRepositoryProvider),
        ref.watch(activityLoggerProvider),
      );
    });

// ---------------------------------------------------------------------------
// Role & permission helpers (derived from userProfileProvider)
// ---------------------------------------------------------------------------

/// The current user's role (defaults to `user` when profile is unavailable).
final userRoleProvider = Provider<UserRole>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.role ?? UserRole.user;
});

/// The current user's computed permissions.
final userPermissionsProvider = Provider<UserPermissions>((ref) {
  final role = ref.watch(userRoleProvider);
  return UserPermissions.fromRole(role);
});
