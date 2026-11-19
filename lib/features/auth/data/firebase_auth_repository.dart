import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? fb.FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<fb.User?> userChanges() => _auth.userChanges();

  @override
  fb.User? get currentUser => _auth.currentUser;

  @override
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthException(AuthFailure.cancelled);
      }
      final auth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      await _auth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } on PlatformException catch (e) {
      // google_sign_in reports failures as PlatformException. "sign_in_failed"
      // with ApiException 10 means the app's SHA fingerprint isn't registered
      // in Firebase. Keep it visible in debug logs instead of hiding it.
      debugPrint('Google sign-in failed: ${e.code} ${e.message}');
      throw AuthException(
        e.code == GoogleSignIn.kNetworkError
            ? AuthFailure.network
            : AuthFailure.generic,
      );
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // userChanges() emits again once the name is saved, so Home updates.
      await credential.user?.updateDisplayName(name);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  AuthFailure _mapCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthFailure.invalidEmail;
      case 'weak-password':
        return AuthFailure.weakPassword;
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.wrongPassword;
      case 'user-not-found':
        return AuthFailure.userNotFound;
      case 'email-already-in-use':
        return AuthFailure.emailInUse;
      case 'network-request-failed':
        return AuthFailure.network;
      default:
        return AuthFailure.generic;
    }
  }
}
