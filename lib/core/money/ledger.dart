/// Net balances (PLAN.md §4). Balances are never stored: they're recomputed
/// from expenses and settlements every time.
library;

import 'allocation.dart';
import 'money_exception.dart';

/// The only parts of an expense the balance math needs.
class LedgerExpense {
  const LedgerExpense({
    required this.amount,
    required this.payers,
    required this.shares,
  });

  final int amount;

  /// memberId → paisa paid; sums to [amount].
  final Map<String, int> payers;

  /// memberId → paisa owed; sums to [amount].
  final Map<String, int> shares;

  /// Throws if payers or shares don't sum exactly to [amount].
  void validate() {
    if (amount <= 0) {
      throw const MoneyException('Expense amount must be positive.');
    }
    if (sumOf(payers) != amount) {
      throw MoneyException('Payers sum to ${sumOf(payers)}, not $amount.');
    }
    if (sumOf(shares) != amount) {
      throw MoneyException('Shares sum to ${sumOf(shares)}, not $amount.');
    }
    if ([...payers.values, ...shares.values].any((v) => v < 0)) {
      throw const MoneyException('Amounts cannot be negative.');
    }
  }
}

/// A payment from [from] to [to]. Pass only settlements that count
/// (confirmed ones); pending settlements must not change balances.
class LedgerSettlement {
  const LedgerSettlement({
    required this.from,
    required this.to,
    required this.amount,
  });

  final String from;
  final String to;
  final int amount;
}

/// `net = totalPaid − totalShares + settlementsPaid − settlementsReceived`.
/// Positive = is owed, negative = owes. Always sums to 0 across the group.
///
/// [members] seeds everyone at 0 so people with no activity still appear.
/// True when a confirmed payment of [amount] from [from] to [to] brings
/// every net in [nets] to zero: the group is fully settled.
bool settlesEveryone(
  Map<String, int> nets, {
  required String from,
  required String to,
  required int amount,
}) {
  for (final MapEntry(key: id, value: net) in nets.entries) {
    final after = net + (id == from ? amount : 0) - (id == to ? amount : 0);
    if (after != 0) return false;
  }
  return nets.containsKey(from) && nets.containsKey(to);
}

Map<String, int> netBalances({
  required Iterable<LedgerExpense> expenses,
  Iterable<LedgerSettlement> settlements = const [],
  Iterable<String> members = const [],
}) {
  final net = <String, int>{for (final id in members) id: 0};
  void add(String id, int paisa) => net[id] = (net[id] ?? 0) + paisa;

  for (final expense in expenses) {
    expense.validate();
    expense.payers.forEach(add);
    expense.shares.forEach((id, paisa) => add(id, -paisa));
  }
  for (final s in settlements) {
    if (s.amount <= 0) {
      throw const MoneyException('Settlement amount must be positive.');
    }
    if (s.from == s.to) {
      throw const MoneyException('Someone cannot settle with themselves.');
    }
    add(s.from, s.amount);
    add(s.to, -s.amount);
  }

  assert(sumOf(net) == 0, 'Group nets must sum to zero');
  return net;
}
