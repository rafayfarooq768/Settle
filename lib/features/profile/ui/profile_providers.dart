import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_provider.dart';
import '../../auth/ui/auth_providers.dart';
import '../data/user_repository.dart';
import '../domain/app_user.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

/// The signed-in user's profile doc, or null while signed out.
final myProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(userChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watch(uid);
});

/// Creates `users/{uid}` after sign-in. Watched once by the app root.
/// Failures (e.g. offline) are retried on the next auth change or launch.
final ensureProfileProvider = Provider<void>((ref) {
  ref.listen(userChangesProvider, (_, next) {
    final user = next.valueOrNull;
    if (user == null) return;
    ref
        .read(userRepositoryProvider)
        .ensureUser(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
        )
        .catchError((Object e) => debugPrint('ensureUser failed: $e'));
  }, fireImmediately: true);
});
