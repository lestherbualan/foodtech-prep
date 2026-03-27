import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/auth_repository.dart';

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
// Auth state stream (drives router redirects)
// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Auth action notifier (Google sign-in / sign-out)
// ---------------------------------------------------------------------------
class AuthActionNotifier extends StateNotifier<AsyncValue<void>> {
  AuthActionNotifier(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithGoogle();
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.signOut());
  }
}

final authActionProvider =
    StateNotifierProvider<AuthActionNotifier, AsyncValue<void>>((ref) {
      return AuthActionNotifier(ref.watch(authRepositoryProvider));
    });
