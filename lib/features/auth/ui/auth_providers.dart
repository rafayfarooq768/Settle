import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Current user, updated on sign-in, sign-out and profile changes.
final userChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).userChanges();
});
