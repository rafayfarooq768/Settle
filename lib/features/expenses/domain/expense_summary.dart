import '../../../core/money/money.dart';
import '../../../core/firestore/firestore_fields.dart';
import 'expense.dart';

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

/// An Equal-split expense paid by one person (PLAN.md step 5). Throws
/// [MoneyException] if nobody is ticked. Participants are stored in
/// `splitInput` so it can be edited in the same mode later.
ExpenseDraft equalDraft({
  required String title,
  required int amount,
  required DateTime date,
  required String payerId,
  required List<String> participants,
}) => ExpenseDraft(
  title: title.trim(),
  amount: amount,
  date: date,
  splitMode: SplitMode.equal,
  payers: {payerId: amount},
  shares: splitEqual(
    amount: amount,
    participants: participants,
    payers: [payerId],
  ),
  splitInput: <String, Object?>{'participants': participants},
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
