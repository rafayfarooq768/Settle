import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../../../core/money/money.dart';
import '../../activity/data/activity_log.dart';
import '../../activity/domain/activity.dart';
import '../domain/settlement.dart';
import '../../../core/firestore/retry_when_denied.dart';

/// Settle flow (PLAN.md §3 item 10). Security rules decide who may create,
/// confirm or remove each settlement.
class SettlementRepository {
  SettlementRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Json> _group(String groupId) =>
      _db.collection(Col.groups).doc(groupId);
  CollectionReference<Json> _settlements(String groupId) =>
      _group(groupId).collection(Col.settlements);

  Stream<List<Settlement>> watch(String groupId) =>
      retryWhenDenied(
        () =>
            _settlements(groupId)
                .orderBy('createdAt', descending: true)
                .snapshots(includeMetadataChanges: true),
      ).map(
        (s) => [
          for (final d in s.docs)
            ?settlementFromMap(
              d.id,
              d.data(),
              pendingSync: d.metadata.hasPendingWrites,
            ),
        ],
      );

  /// "I paid" → pending until [to] confirms. Or, when [confirmed] is true,
  /// the person paid records it directly.
  Future<String> record({
    required String groupId,
    required String uid,
    required String actorMemberId,
    required String from,
    required String to,
    required int amount,
    bool confirmed = false,
  }) async {
    if (amount <= 0) {
      throw const MoneyException('Settlement amount must be positive.');
    }
    if (from == to) {
      throw const MoneyException('Someone cannot settle with themselves.');
    }
    final doc = _settlements(groupId).doc();
    final batch = _db.batch()
      ..set(doc, {
        'from': from,
        'to': to,
        'amount': amount,
        'status':
            (confirmed ? SettlementStatus.confirmed : SettlementStatus.pending)
                .name,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'confirmedAt': confirmed ? FieldValue.serverTimestamp() : null,
      });
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.settlementRecorded,
      actorMemberId: actorMemberId,
      targetId: doc.id,
      // Status too, so the activity log can say "sent" or "recorded".
      after: {
        'from': from,
        'to': to,
        'amount': amount,
        'status':
            (confirmed ? SettlementStatus.confirmed : SettlementStatus.pending)
                .name,
      },
    );
    await commitOrQueue(batch);
    return doc.id;
  }

  Future<void> confirm({
    required String groupId,
    required String actorMemberId,
    required Settlement settlement,
  }) async {
    final batch = _db.batch()
      ..update(_settlements(groupId).doc(settlement.id), {
        'status': SettlementStatus.confirmed.name,
        'confirmedAt': FieldValue.serverTimestamp(),
      });
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.settlementConfirmed,
      actorMemberId: actorMemberId,
      targetId: settlement.id,
    );
    await commitOrQueue(batch);
  }

  /// Cancel a pending "I paid", reject one, or undo a recorded payment.
  Future<void> remove({
    required String groupId,
    required String actorMemberId,
    required Settlement settlement,
  }) async {
    final batch = _db.batch()..delete(_settlements(groupId).doc(settlement.id));
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.settlementDeleted,
      actorMemberId: actorMemberId,
      targetId: settlement.id,
      before: {
        'from': settlement.from,
        'to': settlement.to,
        'amount': settlement.amount,
        'status': settlement.status.name,
      },
    );
    await commitOrQueue(batch);
  }
}

Settlement? settlementFromMap(
  String id,
  Json data, {
  bool pendingSync = false,
}) {
  final amount = data['amount'];
  final status = readEnum(SettlementStatus.values, data['status']);
  if (amount is! int || status == null) return null;
  return Settlement(
    id: id,
    from: readString(data['from']),
    to: readString(data['to']),
    amount: amount,
    status: status,
    createdBy: readString(data['createdBy']),
    createdAt: readDate(data['createdAt']),
    confirmedAt: readOptionalDate(data['confirmedAt']),
    pendingSync: pendingSync,
  );
}
