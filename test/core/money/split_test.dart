import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';

void main() {
  group('allocate', () {
    test('leftover paisa go in order, payer first', () {
      // 100 paisa among 3: 33 each + 1 leftover to the first in order.
      expect(
        allocate(
          total: 100,
          weights: {'a': 1, 'b': 1, 'c': 1},
          order: ['b', 'a', 'c'],
        ),
        {'b': 34, 'a': 33, 'c': 33},
      );
    });

    test('zero-weight members get nothing, not even leftover', () {
      expect(
        allocate(
          total: 101,
          weights: {'a': 0, 'b': 1, 'c': 1},
          order: ['a', 'b', 'c'],
        ),
        {'a': 0, 'b': 51, 'c': 50},
      );
    });

    test('rejects no weights, negatives, and members missing from order', () {
      expect(
        () => allocate(total: 100, weights: {'a': 0}, order: ['a']),
        throwsA(isA<MoneyException>()),
      );
      expect(
        () => allocate(total: -1, weights: {'a': 1}, order: ['a']),
        throwsA(isA<MoneyException>()),
      );
      expect(
        () => allocate(total: 100, weights: {'a': 1}, order: ['b']),
        throwsA(isA<MoneyException>()),
      );
    });

    test('payerFirstOrder puts payers first without duplicates', () {
      expect(payerFirstOrder(members: ['a', 'b', 'c'], payers: ['c']), [
        'c',
        'a',
        'b',
      ]);
    });
  });

  group('equal', () {
    test('one participant takes the whole amount', () {
      expect(splitEqual(amount: 12345, participants: ['a']), {'a': 12345});
    });

    test('needs at least one participant', () {
      expect(
        () => splitEqual(amount: 100, participants: []),
        throwsA(isA<MoneyException>()),
      );
    });

    test('payer not in the split does not get leftover paisa', () {
      final shares = splitEqual(
        amount: 100,
        participants: ['b', 'c', 'd'],
        payers: ['a'],
      );
      expect(shares, {'b': 34, 'c': 33, 'd': 33});
    });
  });

  group('exact', () {
    test('accepts amounts that sum to the total', () {
      expect(splitExact(amount: 500, amounts: {'a': 200, 'b': 300}), {
        'a': 200,
        'b': 300,
      });
    });

    test('blocks amounts that do not sum to the total', () {
      expect(
        () => splitExact(amount: 500, amounts: {'a': 200, 'b': 200}),
        throwsA(isA<MoneyException>()),
      );
    });

    test('remaining drives "Rs X left to assign"', () {
      expect(exactRemaining(amount: 500, amounts: {'a': 200}), 300);
      expect(exactRemaining(amount: 500, amounts: {'a': 600}), -100);
    });
  });

  group('percent', () {
    test('splits by basis points and sums exactly', () {
      final shares = splitPercent(
        amount: 100000,
        basisPoints: {'a': 3333, 'b': 3333, 'c': 3334},
        order: ['a', 'b', 'c'],
      );
      expect(sumOf(shares), 100000);
      expect(shares, {'a': 33330, 'b': 33330, 'c': 33340});
    });

    test('must total 100%', () {
      expect(percentRemaining({'a': 5000, 'b': 4000}), 1000);
      expect(
        () => splitPercent(amount: 100, basisPoints: {'a': 5000}, order: ['a']),
        throwsA(isA<MoneyException>()),
      );
    });
  });

  group('shares', () {
    test('splits by units (e.g. nights)', () {
      // 3 nights + 1 night of Rs 400.
      expect(
        splitShares(amount: 40000, units: {'a': 3, 'b': 1}, order: ['a', 'b']),
        {'a': 30000, 'b': 10000},
      );
    });

    test('needs at least one unit', () {
      expect(
        () => splitShares(amount: 100, units: {'a': 0}, order: ['a']),
        throwsA(isA<MoneyException>()),
      );
    });
  });

  group('itemized', () {
    test('extras can be spread equally', () {
      final shares = splitItemized(
        items: [
          const BillItem(amount: 1000, memberIds: ['a']),
          const BillItem(amount: 3000, memberIds: ['b']),
        ],
        extras: 200,
        spread: ExtrasSpread.equal,
        order: ['a', 'b'],
      );
      expect(shares, {'a': 1100, 'b': 3100});
    });

    test('rejects items with nobody on them', () {
      expect(
        () => splitItemized(
          items: [const BillItem(amount: 100, memberIds: [])],
          order: ['a'],
        ),
        throwsA(isA<MoneyException>()),
      );
    });

    test('percentOf rounds half up to the paisa', () {
      expect(percentOf(amount: 400000, basisPoints: 1000), 40000); // 10%
      expect(percentOf(amount: 105, basisPoints: 5000), 53); // 52.5 → 53
      expect(percentOf(amount: 333, basisPoints: 1600), 53); // 53.28 → 53
    });
  });

  group('ledger', () {
    test('multiple payers', () {
      final nets = netBalances(
        expenses: [
          LedgerExpense(
            amount: 3000,
            payers: {'a': 2000, 'b': 1000},
            shares: {'a': 1000, 'b': 1000, 'c': 1000},
          ),
        ],
      );
      expect(nets, {'a': 1000, 'b': 0, 'c': -1000});
    });

    test('a confirmed settlement clears the debt', () {
      final nets = netBalances(
        expenses: [
          const LedgerExpense(
            amount: 600,
            payers: {'a': 600},
            shares: {'a': 300, 'b': 300},
          ),
        ],
        settlements: [const LedgerSettlement(from: 'b', to: 'a', amount: 300)],
      );
      expect(nets, {'a': 0, 'b': 0});
    });

    test(
      'rejects expenses whose payers or shares do not sum to the amount',
      () {
        expect(
          () => netBalances(
            expenses: [
              const LedgerExpense(
                amount: 600,
                payers: {'a': 500},
                shares: {'a': 600},
              ),
            ],
          ),
          throwsA(isA<MoneyException>()),
        );
        expect(
          () => netBalances(
            expenses: [
              const LedgerExpense(
                amount: 600,
                payers: {'a': 600},
                shares: {'a': 599},
              ),
            ],
          ),
          throwsA(isA<MoneyException>()),
        );
      },
    );

    test('members with no activity appear at 0', () {
      expect(netBalances(expenses: [], members: ['a', 'b']), {'a': 0, 'b': 0});
    });
  });

  group('simplify', () {
    test('everyone settled → no transfers', () {
      expect(simplifyDebts({'a': 0, 'b': 0}), isEmpty);
    });

    test('rejects nets that do not sum to zero', () {
      expect(() => simplifyDebts({'a': 100}), throwsA(isA<MoneyException>()));
    });
  });
}
