import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../domain/expense.dart';
import '../domain/expense_summary.dart';

/// Null if the doc can't be read as money (missing/non-int amounts). Such
/// docs are skipped rather than crashing the list or the balances.
Expense? expenseFromMap(String id, Json data, {bool pendingSync = false}) {
  final amount = data['amount'];
  final payers = readPaisaMap(data['payers']);
  final shares = readPaisaMap(data['shares']);
  if (amount is! int || payers == null || shares == null) return null;
  return Expense(
    id: id,
    title: readString(data['title']),
    amount: amount,
    date: readDate(data['date']),
    createdBy: readString(data['createdBy']),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    splitMode: readEnum(SplitMode.values, data['splitMode']) ?? SplitMode.exact,
    payers: payers,
    shares: shares,
    splitInput: readJson(data['splitInput']) ?? const {},
    note: readString(data['note']),
    deleted: readBool(data['deleted']),
    pendingSync: pendingSync,
  );
}

/// The fields a person edits. Written as-is on add and edit.
Json expenseFields(ExpenseDraft draft) => {
  'title': draft.title,
  'amount': draft.amount,
  'date': Timestamp.fromDate(draft.date),
  'splitMode': draft.splitMode.name,
  'payers': draft.payers,
  'shares': draft.shares,
  'splitInput': draft.splitInput,
  'note': draft.note,
};

/// A compact copy for the activity log's before/after.
Json expenseSnapshot(ExpenseDraft draft) => {
  'title': draft.title,
  'amount': draft.amount,
  'date': Timestamp.fromDate(draft.date),
  'payers': draft.payers,
  'shares': draft.shares,
};
