import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_provider.dart';
import '../data/activity_repository.dart';
import '../domain/activity.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(firestoreProvider)),
);

/// Only while the Activity screen is open.
final activityProvider = StreamProvider.autoDispose
    .family<List<Activity>, String>(
      (ref, groupId) => ref.watch(activityRepositoryProvider).watch(groupId),
    );

/// One expense's history, while its detail screen is open.
final targetActivityProvider = StreamProvider.autoDispose
    .family<List<Activity>, ({String groupId, String targetId})>(
      (ref, key) => ref
          .watch(activityRepositoryProvider)
          .watchFor(key.groupId, key.targetId),
    );
