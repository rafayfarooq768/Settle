import '../../../core/money/money.dart';
import '../../../core/firestore/firestore_fields.dart';
import 'expense.dart';
import 'split_spec.dart';

/// Your part in one expense, for the list row (DESIGN.md §6 Lists).
sealed class MyPart {
  const MyPart();
}

/// You weren't a payer or a participant.
class NotInvolved extends MyPart {
  const NotInvolved();
}

/// You paid exactly your own share.
class Even extends MyPart {
  const Even();
}

/// You paid more than your share: others owe you [amount].
class Lent extends MyPart {
  const Lent(this.amount);
  final int amount;
}

/// You paid less than your share: you owe [amount].
class Owe extends MyPart {
  const Owe(this.amount);
  final int amount;
}

MyPart myPart(Expense e, String memberId) {
  final paid = e.payers[memberId];
  final share = e.shares[memberId];
  if (paid == null && share == null) return const NotInvolved();
  final diff = (paid ?? 0) - (share ?? 0);
  return switch (diff.sign) {
    0 => const Even(),
    1 => Lent(diff),
    _ => Owe(-diff),
  };
}

/// An expense split as [split] says. [payers] is who paid what (one
/// person: `{id: amount}`); it must add up to [amount] too. Throws
/// [MoneyException] if either doesn't add up. [order] is the group's
/// member order (leftover paisa go to payers first, then in this order).
ExpenseDraft splitDraft({
  required String title,
  required int amount,
  required DateTime date,
  required Map<String, int> payers,
  required SplitSpec split,
  required List<String> order,
}) {
  final paid = ExactSpec(payers);
  if (paid.problem(amount) != null) {
    throw const MoneyException('Paid amounts must add up to the total.');
  }
  final payerIds = [
    for (final id in order)
      if (payers.containsKey(id)) id,
  ];
  return ExpenseDraft(
    title: title.trim(),
    amount: amount,
    date: date,
    splitMode: split.mode,
    payers: paid.shares(amount: amount, order: order, payers: payerIds),
    shares: split.shares(amount: amount, order: order, payers: payerIds),
    splitInput: split.toJson(),
  );
}

/// An Equal-split expense paid by one person. Throws [MoneyException] if
/// nobody is ticked.
ExpenseDraft equalDraft({
  required String title,
  required int amount,
  required DateTime date,
  required String payerId,
  required List<String> participants,
}) => splitDraft(
  title: title,
  amount: amount,
  date: date,
  payers: {payerId: amount},
  split: EqualSpec(participants),
  order: participants,
);

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

/// Largest amount the rules accept: Rs 1 billion, in paisa.
const int maxExpenseAmount = 100000000000;
