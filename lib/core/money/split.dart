/// Split modes (PLAN.md §4). Each returns shares `{memberId: paisa}` that sum
/// exactly to the expense amount. The balance math only ever sees these
/// shares, never the mode.
library;

import 'allocation.dart';
import 'money_exception.dart';

/// 100% in basis points. Percentages are ints (1 bp = 0.01%) so no `double`
/// touches money: 33.33% is 3333.
const int fullPercentBp = 10000;

/// Equal: split among [participants]; leftover paisa go payer-first.
Map<String, int> splitEqual({
  required int amount,
  required List<String> participants,
  Iterable<String> payers = const [],
}) {
  if (participants.isEmpty) {
    throw const MoneyException('Pick at least one person.');
  }
  return allocate(
    total: amount,
    weights: {for (final id in participants) id: 1},
    order: payerFirstOrder(members: participants, payers: payers),
  );
}

/// Exact: amounts per person, which must sum to [amount].
Map<String, int> splitExact({
  required int amount,
  required Map<String, int> amounts,
}) {
  if (amounts.values.any((a) => a < 0)) {
    throw const MoneyException('Amounts cannot be negative.');
  }
  final left = exactRemaining(amount: amount, amounts: amounts);
  if (left != 0) {
    throw MoneyException('Exact amounts are off by $left paisa.');
  }
  return Map.of(amounts);
}

/// Paisa still to assign in Exact mode (negative = over-assigned).
/// Drives the live "Rs X left to assign" line (DESIGN.md §11).
int exactRemaining({required int amount, required Map<String, int> amounts}) =>
    amount - sumOf(amounts);

/// Percent: basis points per person, which must sum to 100% (10000).
Map<String, int> splitPercent({
  required int amount,
  required Map<String, int> basisPoints,
  required List<String> order,
  Iterable<String> payers = const [],
}) {
  final left = percentRemaining(basisPoints);
  if (left != 0) {
    throw MoneyException('Percentages are off by $left basis points.');
  }
  return allocate(
    total: amount,
    weights: basisPoints,
    order: payerFirstOrder(members: order, payers: payers),
  );
}

/// Basis points still to assign in Percent mode (negative = over 100%).
int percentRemaining(Map<String, int> basisPoints) =>
    fullPercentBp - sumOf(basisPoints);

/// Shares: units per person (e.g. nights stayed); at least 1 unit in total.
Map<String, int> splitShares({
  required int amount,
  required Map<String, int> units,
  required List<String> order,
  Iterable<String> payers = const [],
}) {
  if (sumOf(units) < 1) {
    throw const MoneyException('Give at least one share to someone.');
  }
  return allocate(
    total: amount,
    weights: units,
    order: payerFirstOrder(members: order, payers: payers),
  );
}

/// One line on a bill, shared equally by [memberIds] (one id = personal item).
class BillItem {
  const BillItem({required this.amount, required this.memberIds});

  final int amount;
  final List<String> memberIds;
}

/// Itemized: items → people, plus [extras] (tax + service charge, in
/// paisa) in proportion to what each person had, plus a [tip]: equally
/// among everyone who had an item, or equally among [tipBy] (one or more
/// people, owner 2026-11-20). Returns shares summing to items total +
/// extras + tip.
Map<String, int> splitItemized({
  required List<BillItem> items,
  required List<String> order,
  int extras = 0,
  int tip = 0,
  Iterable<String> tipBy = const [],
  Iterable<String> payers = const [],
}) {
  if (items.isEmpty) {
    throw const MoneyException('Add at least one item.');
  }
  if (extras < 0 || tip < 0) {
    throw const MoneyException('Tax, service and tip cannot be negative.');
  }
  if (tipBy.any((id) => !order.contains(id))) {
    throw const MoneyException('Who gives the tip must be in the group.');
  }
  final stable = payerFirstOrder(members: order, payers: payers);

  final subtotals = <String, int>{};
  for (final item in items) {
    if (item.memberIds.isEmpty) {
      throw const MoneyException('Every item needs at least one person.');
    }
    final itemShares = splitEqual(
      amount: item.amount,
      participants: [
        for (final id in stable)
          if (item.memberIds.contains(id)) id,
      ],
    );
    itemShares.forEach((id, paisa) {
      subtotals[id] = (subtotals[id] ?? 0) + paisa;
    });
  }

  final shares = {...subtotals};
  void add(Map<String, int> more) => more.forEach((id, paisa) {
    shares[id] = (shares[id] ?? 0) + paisa;
  });

  if (extras > 0) {
    add(allocate(total: extras, weights: subtotals, order: stable));
  }
  if (tip > 0) {
    final givers = tipBy.isEmpty ? subtotals.keys : tipBy;
    add(
      allocate(
        total: tip,
        weights: {for (final id in givers) id: 1},
        order: stable,
      ),
    );
  }
  return shares;
}

/// [basisPoints] percent of [amount], rounded half up to the paisa.
/// Use for tax/service given as a percentage (10% = 1000 bp).
int percentOf({required int amount, required int basisPoints}) {
  if (amount < 0 || basisPoints < 0) {
    throw const MoneyException('Amount and percentage cannot be negative.');
  }
  return (amount * basisPoints + fullPercentBp ~/ 2) ~/ fullPercentBp;
}
