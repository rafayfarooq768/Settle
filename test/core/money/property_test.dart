// Randomized checks of the PLAN.md §10 invariants. Fixed seed, so a failure
// is reproducible; the failing case is printed in the reason.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';

const _runs = 2000;

void main() {
  final random = Random(20261119);

  List<String> randomMembers() =>
      List.generate(1 + random.nextInt(8), (i) => 'm$i');

  int randomAmount() => 1 + random.nextInt(10000000); // up to Rs 1 lakh

  /// A random expense in a random split mode, as the app would build it.
  LedgerExpense randomExpense(List<String> members) {
    final amount = randomAmount();
    final payer = members[random.nextInt(members.length)];
    final participants = members.where((_) => random.nextBool()).toList();
    if (participants.isEmpty) participants.add(payer);

    final Map<String, int> shares;
    switch (random.nextInt(4)) {
      case 0:
        shares = splitEqual(
          amount: amount,
          participants: participants,
          payers: [payer],
        );
      case 1:
        final units = {for (final id in participants) id: random.nextInt(5)};
        if (sumOf(units) == 0) units[participants.first] = 1;
        shares = splitShares(
          amount: amount,
          units: units,
          order: members,
          payers: [payer],
        );
      case 2:
        // Random percentages summing to exactly 100%.
        var left = fullPercentBp;
        final bp = <String, int>{};
        for (var i = 0; i < participants.length; i++) {
          final last = i == participants.length - 1;
          final take = last ? left : random.nextInt(left + 1);
          bp[participants[i]] = take;
          left -= take;
        }
        shares = splitPercent(
          amount: amount,
          basisPoints: bp,
          order: members,
          payers: [payer],
        );
      default:
        final items = List.generate(1 + random.nextInt(4), (_) {
          final eaters = participants.where((_) => random.nextBool()).toList();
          return BillItem(
            amount: randomAmount() ~/ 4 + 1,
            memberIds: eaters.isEmpty ? [participants.first] : eaters,
          );
        });
        final subtotal = items.fold<int>(0, (s, i) => s + i.amount);
        shares = splitItemized(
          items: items,
          extras: percentOf(
            amount: subtotal,
            basisPoints: random.nextInt(2500),
          ),
          spread: random.nextBool()
              ? ExtrasSpread.proportional
              : ExtrasSpread.equal,
          order: members,
          payers: [payer],
        );
    }
    final total = sumOf(shares);
    return LedgerExpense(amount: total, payers: {payer: total}, shares: shares);
  }

  test('every split mode: shares sum exactly to the amount', () {
    for (var run = 0; run < _runs; run++) {
      final members = randomMembers();
      final expense = randomExpense(members);
      expect(
        sumOf(expense.shares),
        expense.amount,
        reason: 'run $run: ${expense.shares}',
      );
      expect(expense.shares.values, everyElement(greaterThanOrEqualTo(0)));
    }
  });

  test('equal split: shares differ by at most 1 paisa', () {
    for (var run = 0; run < _runs; run++) {
      final members = randomMembers();
      final shares = splitEqual(amount: randomAmount(), participants: members);
      final values = shares.values;
      expect(values.reduce(max) - values.reduce(min), lessThanOrEqualTo(1));
    }
  });

  test(
    'group nets sum to 0; simplify settles everyone in ≤ n − 1 payments',
    () {
      for (var run = 0; run < _runs ~/ 4; run++) {
        final members = randomMembers();
        final expenses = List.generate(
          1 + random.nextInt(10),
          (_) => randomExpense(members),
        );
        final settlements = <LedgerSettlement>[
          if (members.length > 1 && random.nextBool())
            LedgerSettlement(
              from: members[0],
              to: members[1],
              amount: randomAmount(),
            ),
        ];
        final nets = netBalances(
          expenses: expenses,
          settlements: settlements,
          members: members,
        );
        expect(sumOf(nets), 0, reason: 'run $run');

        final transfers = simplifyDebts(nets, order: members);
        final nonZero = nets.values.where((n) => n != 0).length;
        expect(
          transfers.length,
          lessThanOrEqualTo(max(0, nonZero - 1)),
          reason: 'run $run',
        );
        expect(transfers.map((t) => t.amount), everyElement(greaterThan(0)));

        // Applying the transfers as settlements brings everyone to 0.
        final after = netBalances(
          expenses: expenses,
          settlements: [
            ...settlements,
            for (final t in transfers)
              LedgerSettlement(from: t.from, to: t.to, amount: t.amount),
          ],
          members: members,
        );
        expect(after.values, everyElement(0), reason: 'run $run: $nets');
      }
    },
  );
}
