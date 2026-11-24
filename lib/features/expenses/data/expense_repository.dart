import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../../../core/money/money.dart';
import '../../activity/data/activity_log.dart';
import '../../activity/domain/activity.dart';
import '../domain/expense.dart';
import '../domain/expense_summary.dart';
import 'expense_mapper.dart';
import '../../../core/firestore/retry_when_denied.dart';

/// Expenses of one group. Never hard-deletes (PLAN.md §7 soft delete), and
/// refuses to write anything that breaks the money rules.
class ExpenseRepository {
  ExpenseRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Json> _group(String groupId) =>
      _db.collection(Col.groups).doc(groupId);
  CollectionReference<Json> _expenses(String groupId) =>
      _group(groupId).collection(Col.expenses);

  /// Newest first, including deleted ones (needed for Undo and history).
  /// Metadata changes too, so a row's "Not synced yet" clears once the
  /// server has it (metadata-only updates cost no reads).
  Stream<List<Expense>> watch(String groupId) =>
      retryWhenDenied(
        () =>
            _expenses(groupId)
                .orderBy('date', descending: true)
                .snapshots(includeMetadataChanges: true),
      ).map(
        (s) => [
          for (final d in s.docs)
            ?expenseFromMap(
              d.id,
              d.data(),
              pendingSync: d.metadata.hasPendingWrites,
            ),
        ],
      );

  /// Returns the new expense id. Throws [MoneyException] if payers or shares
  /// don't sum exactly to the amount.
  Future<String> add({
    required String groupId,
    required String uid,
    required String actorMemberId,
    required ExpenseDraft draft,
  }) async {
    _validate(draft);
    final doc = _expenses(groupId).doc();
    final batch = _db.batch()
      ..set(doc, {
        ...expenseFields(draft),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': false,
      });
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.expenseAdded,
      actorMemberId: actorMemberId,
      targetId: doc.id,
      summary: draft.title,
      after: expenseSnapshot(draft),
    );
    await commitOrQueue(batch);
    return doc.id;
  }

  Future<void> edit({
    required String groupId,
    required String actorMemberId,
    required Expense before,
    required ExpenseDraft draft,
  }) async {
    _validate(draft);
    final batch = _db.batch()
      ..update(_expenses(groupId).doc(before.id), {
        ...expenseFields(draft),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.expenseEdited,
      actorMemberId: actorMemberId,
      targetId: before.id,
      summary: draft.title,
      before: expenseSnapshot(ExpenseDraft.of(before)),
      after: expenseSnapshot(draft),
    );
    await commitOrQueue(batch);
  }

  /// Delete ([deleted] true) or Undo ([deleted] false).
  Future<void> setDeleted({
    required String groupId,
    required String actorMemberId,
    required Expense expense,
    required bool deleted,
  }) async {
    final batch = _db.batch()
      ..update(_expenses(groupId).doc(expense.id), {
        'deleted': deleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    logActivity(
      batch,
      _group(groupId),
      type: deleted
          ? ActivityType.expenseDeleted
          : ActivityType.expenseRestored,
      actorMemberId: actorMemberId,
      targetId: expense.id,
      summary: expense.title,
      before: deleted ? expenseSnapshot(ExpenseDraft.of(expense)) : null,
    );
    await commitOrQueue(batch);
  }

  void _validate(ExpenseDraft draft) {
    if (draft.title.trim().isEmpty) {
      throw const MoneyException('An expense needs a title.');
    }
    LedgerExpense(
      amount: draft.amount,
      payers: draft.payers,
      shares: draft.shares,
    ).validate();
  }
}
