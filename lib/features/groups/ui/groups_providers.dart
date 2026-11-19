import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_provider.dart';
import '../../auth/ui/auth_providers.dart';
import '../data/group_repository.dart';
import '../domain/group.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(ref.watch(firestoreProvider)),
);

/// Groups the signed-in user belongs to (Home).
final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  final uid = ref.watch(userChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(groupRepositoryProvider).watchMyGroups(uid);
});

// autoDispose: listen to a group only while its screen is open (CLAUDE.md).
final groupProvider = StreamProvider.autoDispose.family<Group?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final membersProvider = StreamProvider.autoDispose.family<List<Member>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchMembers(groupId),
);
