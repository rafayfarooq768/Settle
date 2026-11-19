/// Pure Dart. No Flutter or Firebase imports in lib/core/money (CLAUDE.md).
library;

import 'money_exception.dart';

/// Splits [total] paisa across members in proportion to [weights].
///
/// PLAN.md §4 rounding rule: floor each share, then give the leftover paisa
/// one at a time to members in [order] (callers put the payer first). Only
/// members with a positive weight receive leftover paisa. The result always
/// sums exactly to [total].
///
/// Every key in [weights] must appear in [order]. Members with weight 0 get 0.
Map<String, int> allocate({
  required int total,
  required Map<String, int> weights,
  required List<String> order,
}) {
  if (total < 0) {
    throw const MoneyException('Amount cannot be negative.');
  }
  if (weights.values.any((w) => w < 0)) {
    throw const MoneyException('Weights cannot be negative.');
  }
  final missing = weights.keys.where((id) => !order.contains(id));
  if (missing.isNotEmpty) {
    throw MoneyException('Members missing from order: ${missing.join(', ')}');
  }

  final weightSum = weights.values.fold<int>(0, (a, b) => a + b);
  if (weightSum == 0) {
    throw const MoneyException('At least one member must have a share.');
  }

  final shares = <String, int>{};
  var assigned = 0;
  for (final id in order) {
    final weight = weights[id];
    if (weight == null) continue;
    // Integer floor division; total * weight stays well inside 64-bit ints
    // for any realistic amount (Rs 10 crore * 10,000 basis points ≈ 1e13).
    final share = total * weight ~/ weightSum;
    shares[id] = share;
    assigned += share;
  }

  var leftover = total - assigned;
  // leftover < number of positive-weight members, so one pass is enough.
  for (final id in order) {
    if (leftover == 0) break;
    if ((weights[id] ?? 0) > 0) {
      shares[id] = shares[id]! + 1;
      leftover--;
    }
  }
  assert(leftover == 0);
  return shares;
}

/// The stable order for leftover paisa: payers first (in their given order),
/// then everyone else in [members] order. Duplicates are removed.
List<String> payerFirstOrder({
  required List<String> members,
  required Iterable<String> payers,
}) {
  final order = <String>[];
  for (final id in [...payers, ...members]) {
    if (!order.contains(id)) order.add(id);
  }
  return order;
}

int sumOf(Map<String, int> amounts) =>
    amounts.values.fold<int>(0, (a, b) => a + b);
