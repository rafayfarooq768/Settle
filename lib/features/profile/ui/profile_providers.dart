import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_provider.dart';
import '../../auth/ui/auth_providers.dart';
import '../data/user_repository.dart';
import '../domain/app_user.dart';
import '../domain/payment_method.dart';

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

/// Who "I" am when creating or joining a group: the profile name if set,
/// else the sign-in name, else the email.
class MyIdentity {
  const MyIdentity({
    required this.uid,
    required this.name,
    this.paymentMethods = const [],
  });

  final String uid;
  final String name;
  final List<PaymentMethod> paymentMethods;
}

final myIdentityProvider = Provider<MyIdentity?>((ref) {
  final user = ref.watch(userChangesProvider).valueOrNull;
  if (user == null) return null;
  final profile = ref.watch(myProfileProvider).valueOrNull;
  final candidates = [profile?.displayName, user.displayName, user.email];
  final name = candidates
      .map((n) => n?.trim() ?? '')
      .firstWhere((n) => n.isNotEmpty, orElse: () => '');
  return MyIdentity(
    uid: user.uid,
    name: name,
    paymentMethods: profile?.paymentMethods ?? const [],
  );
});
