import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../domain/activity.dart';
import 'activity_log.dart';
import '../../../core/firestore/retry_when_denied.dart';

/// Reads the activity log. Entries are written by the other repositories
/// via [logActivity], inside the same batch as the change.
class ActivityRepository {
  ActivityRepository(this._db);

  final FirebaseFirestore _db;

  /// Newest first. [limit] keeps reads low on long-lived groups.
  Stream<List<Activity>> watch(String groupId, {int limit = 100}) =>
      retryWhenDenied(
        () => _db
            .collection(Col.groups)
            .doc(groupId)
            .collection(Col.activity)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots(),
      ).map(
        (snap) => [
          for (final doc in snap.docs) ?activityFromMap(doc.id, doc.data()),
        ],
      );
}
