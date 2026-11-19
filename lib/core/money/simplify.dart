/// Simplified settle-up (PLAN.md §4 "Simplify debts").
library;

import 'allocation.dart';
import 'money_exception.dart';

/// [from] pays [to] [amount] paisa.
class Transfer {
  const Transfer({required this.from, required this.to, required this.amount});

  final String from;
  final String to;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.from == from &&
      other.to == to &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(from, to, amount);

  @override
  String toString() => '$from → $to: $amount';
}

/// Minimum payments that settle everyone: repeatedly match the largest
/// debtor with the largest creditor and transfer `min(|debt|, credit)`.
/// Produces at most `n − 1` transfers.
///
/// Equal amounts break ties by position in [order] (pass the group's member
/// order), then by memberId, so every phone shows the same list.
List<Transfer> simplifyDebts(
  Map<String, int> nets, {
  List<String> order = const [],
}) {
  if (sumOf(nets) != 0) {
    throw MoneyException('Nets must sum to 0, got ${sumOf(nets)}.');
  }

  final creditors = <String, int>{};
  final debtors = <String, int>{};
  nets.forEach((id, net) {
    if (net > 0) creditors[id] = net;
    if (net < 0) debtors[id] = -net;
  });

  int rank(String id) {
    final i = order.indexOf(id);
    return i == -1 ? order.length : i;
  }

  bool comesFirst(String a, String b) {
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank < 0 : a.compareTo(b) < 0;
  }

  String largest(Map<String, int> m) => m.entries.reduce((a, b) {
    if (b.value > a.value) return b;
    if (b.value == a.value && comesFirst(b.key, a.key)) return b;
    return a;
  }).key;

  final transfers = <Transfer>[];
  while (debtors.isNotEmpty && creditors.isNotEmpty) {
    final debtor = largest(debtors);
    final creditor = largest(creditors);
    final debt = debtors[debtor]!;
    final credit = creditors[creditor]!;
    final amount = debt < credit ? debt : credit;

    transfers.add(Transfer(from: debtor, to: creditor, amount: amount));

    if (debt == amount) {
      debtors.remove(debtor);
    } else {
      debtors[debtor] = debt - amount;
    }
    if (credit == amount) {
      creditors.remove(creditor);
    } else {
      creditors[creditor] = credit - amount;
    }
  }
  return transfers;
}
