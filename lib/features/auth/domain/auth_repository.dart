import 'package:firebase_auth/firebase_auth.dart' show User;

/// Errors an [AuthRepository] can throw. UI maps these to localized strings
/// (see lib/l10n/app_en.arb) — never show a raw exception message.
enum AuthFailure {
  invalidEmail,
  weakPassword,
  wrongPassword,
  userNotFound,
  emailInUse,
  network,
  cancelled,
  generic,
}

class AuthException implements Exception {
  const AuthException(this.failure);
  final AuthFailure failure;
}

/// Auth operations the app needs. Firebase calls stay behind this interface
/// (CLAUDE.md: repositories only, no Firebase calls in widgets).
abstract class AuthRepository {
  /// Emits on sign-in, sign-out and profile changes (e.g. display name).
  Stream<User?> userChanges();

  User? get currentUser;

  Future<void> signInWithGoogle();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
