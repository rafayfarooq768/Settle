import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../domain/expense.dart';

/// Null if the doc can't be read as money (missing/non-int amounts). Such
/// docs are skipped rather than crashing the list or the balances.
Expense? expenseFromMap(String id, Json data) {
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

/// What the add/edit form produces.
class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amount,
    required this.date,
    required this.splitMode,
    required this.payers,
    required this.shares,
    this.splitInput = const {},
    this.note = '',
  });

  factory ExpenseDraft.of(Expense e) => ExpenseDraft(
    title: e.title,
    amount: e.amount,
    date: e.date,
    splitMode: e.splitMode,
    payers: e.payers,
    shares: e.shares,
    splitInput: e.splitInput,
    note: e.note,
  );

  final String title;
  final int amount;
  final DateTime date;
  final SplitMode splitMode;
  final Map<String, int> payers;
  final Map<String, int> shares;
  final Json splitInput;
  final String note;
}
