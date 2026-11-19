import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../domain/activity.dart';

/// Adds an activity entry to the same batch as the change it describes, so
/// the log and the data can never disagree (PLAN.md §3 item 12).
void logActivity(
  WriteBatch batch,
  DocumentReference<Json> group, {
  required ActivityType type,
  required String actorMemberId,
  String? targetId,
  String summary = '',
  Json? before,
  Json? after,
}) {
  batch.set(group.collection(Col.activity).doc(), {
    'type': type.name,
    'actorMemberId': actorMemberId,
    'targetId': targetId,
    'summary': summary,
    'before': before,
    'after': after,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Activity? activityFromMap(String id, Json data) {
  final type = readEnum(ActivityType.values, data['type']);
  if (type == null) return null;
  return Activity(
    id: id,
    type: type,
    actorMemberId: readString(data['actorMemberId']),
    createdAt: readDate(data['createdAt']),
    targetId: data['targetId'] as String?,
    summary: readString(data['summary']),
    before: readJson(data['before']),
    after: readJson(data['after']),
  );
}
