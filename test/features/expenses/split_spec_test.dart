import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';
import 'package:settle/features/expenses/domain/split_spec.dart';

const _order = ['a', 'b', 'c', 'd', 'e'];

Map<String, int> _shares(SplitSpec s, int amount, {String payer = 'a'}) =>
    s.shares(amount: amount, order: _order, payers: [payer]);

void main() {
  group('Exact', () {
    test('PLAN.md §4 gaming zone: B pays A 500, C pays A 200', () {
      final draft = splitDraft(
        title: 'Gaming zone',
        amount: 100000,
        date: DateTime(2026, 11, 20),
        payers: {'a': 100000},
        split: const ExactSpec({
          'a': 30000,
          'b': 50000,
          'c': 20000,
          'd': 0,
          'e': 0,
        }),
        order: _order,
      );
      expect(draft.splitMode, SplitMode.exact);
      // D and E had nothing: they're not part of the expense.
      expect(draft.shares, {'a': 30000, 'b': 50000, 'c': 20000});
      final nets = netBalances(
        expenses: [
          LedgerExpense(
            amount: draft.amount,
            payers: draft.payers,
            shares: draft.shares,
          ),
        ],
      );
      expect(simplifyDebts(nets).toSet(), {
        const Transfer(from: 'b', to: 'a', amount: 50000),
        const Transfer(from: 'c', to: 'a', amount: 20000),
      });
    });

    test('says how much is left, or too much', () {
      const spec = ExactSpec({'a': 30000, 'b': 50000});
      expect((spec.problem(100000)! as RupeesLeft).paisa, 20000);
      expect((spec.problem(70000)! as RupeesLeft).paisa, -10000);
      expect(spec.problem(80000), isNull);
    });

    test('needs the amount first', () {
      expect(const ExactSpec({'a': 100}).problem(null), isA<AmountNeeded>());
      expect(const ExactSpec({'a': 100}).problem(0), isA<AmountNeeded>());
    });

    test('refuses to save when it does not add up', () {
      expect(
        () => _shares(const ExactSpec({'a': 100}), 200),
        throwsA(isA<MoneyException>()),
      );
    });
  });

  group('Percent', () {
    test('33.34 / 33.33 / 33.33 of Rs 1000 sums exactly', () {
      final s = _shares(
        const PercentSpec({'a': 3334, 'b': 3333, 'c': 3333}),
        100000,
      );
      expect(s, {'a': 33340, 'b': 33330, 'c': 33330});
      expect(sumOf(s), 100000);
    });

    test('leftover paisa go to the payer first', () {
      // Rs 1 split three ways by percent: 34 / 33 / 33 paisa.
      final s = _shares(
        const PercentSpec({'a': 3333, 'b': 3333, 'c': 3334}),
        100,
        payer: 'b',
      );
      expect(sumOf(s), 100);
      expect(s['b'], greaterThanOrEqualTo(s['a']!));
    });

    test('must add up to 100%', () {
      expect(
        (const PercentSpec({'a': 5000}).problem(1000)! as PercentLeft)
            .basisPoints,
        5000,
      );
      expect(
        (const PercentSpec({'a': 6000, 'b': 5000}).problem(1000)!
                as PercentLeft)
            .basisPoints,
        -1000,
      );
      expect(const PercentSpec({'a': 10000}).problem(null), isNull);
    });
  });

  test('Equal keeps group order and needs someone', () {
    expect(_shares(const EqualSpec(['c', 'a']), 1000), {'a': 500, 'c': 500});
    expect(const EqualSpec([]).problem(100), isA<NobodyPicked>());
  });

  test('every mode reads back from splitInput the same', () {
    final specs = <SplitSpec>[
      const EqualSpec(['a', 'b']),
      const ExactSpec({'a': 300, 'b': 700}),
      const PercentSpec({'a': 2500, 'b': 7500}),
    ];
    for (final spec in specs) {
      final back = SplitSpec.fromJson(spec.mode, spec.toJson())!;
      expect(back.toJson(), spec.toJson());
      expect(_shares(back, 1000), _shares(spec, 1000));
    }
    expect(SplitSpec.fromJson(SplitMode.exact, {'amounts': 'x'}), isNull);
  });

  group('Several payers', () {
    test('PLAN.md §4 chai as one expense: A +700, B +200, C/D/E -300', () {
      final draft = splitDraft(
        title: 'Chai and fries',
        amount: 150000,
        date: DateTime(2026, 11, 20),
        payers: {'a': 100000, 'b': 50000},
        split: const EqualSpec(_order),
        order: _order,
      );
      expect(
        netBalances(
          expenses: [
            LedgerExpense(
              amount: draft.amount,
              payers: draft.payers,
              shares: draft.shares,
            ),
          ],
        ),
        {'a': 70000, 'b': 20000, 'c': -30000, 'd': -30000, 'e': -30000},
      );
    });

    test('leftover paisa go to the payers first', () {
      // Rs 1 among three people; payers are b and c.
      final draft = splitDraft(
        title: 'x',
        amount: 100,
        date: DateTime(2026, 11, 20),
        payers: {'c': 50, 'b': 50},
        split: const EqualSpec(['a', 'b', 'c']),
        order: const ['a', 'b', 'c'],
      );
      expect(draft.shares, {'a': 33, 'b': 34, 'c': 33});
    });

    test('paid amounts must add up to the total', () {
      expect(
        () => splitDraft(
          title: 'x',
          amount: 1000,
          date: DateTime(2026, 11, 20),
          payers: {'a': 600, 'b': 300},
          split: const EqualSpec(['a', 'b']),
          order: const ['a', 'b'],
        ),
        throwsA(isA<MoneyException>()),
      );
    });
  });

  group('Itemized', () {
    // PLAN.md §4 restaurant: a=Ali, b=Sara, c=Bilal, d=Hamza.
    const restaurant = ItemizedSpec(
      items: [
        BillLine(name: 'Steak', amount: 150000, memberIds: ['a']),
        BillLine(name: 'Karahi', amount: 60000, memberIds: ['b']),
        BillLine(name: 'Biryani', amount: 60000, memberIds: ['c']),
        BillLine(name: 'Burger', amount: 50000, memberIds: ['d']),
        BillLine(
          name: 'Drinks',
          amount: 80000,
          memberIds: ['a', 'b', 'c', 'd'],
        ),
      ],
      taxBp: 1000,
    );

    test('PLAN.md §4 restaurant: Ali +2530, Sara -880, Bilal -880, '
        'Hamza -770', () {
      expect(restaurant.total, 440000);
      final draft = splitDraft(
        title: 'Dinner',
        amount: restaurant.total,
        date: DateTime(2026, 11, 20),
        payers: {'a': restaurant.total},
        split: restaurant,
        order: _order,
      );
      expect(
        netBalances(
          expenses: [
            LedgerExpense(
              amount: draft.amount,
              payers: draft.payers,
              shares: draft.shares,
            ),
          ],
        ),
        {'a': 253000, 'b': -88000, 'c': -88000, 'd': -77000},
      );
    });

    test('tax, service and tip all add to the total', () {
      const bill = ItemizedSpec(
        items: [
          BillLine(name: '', amount: 100000, memberIds: ['a', 'b']),
        ],
        taxBp: 1600,
        serviceBp: 500,
        tip: 10000,
      );
      expect(bill.tax, 16000);
      expect(bill.service, 5000);
      expect(bill.total, 131000);
      expect(sumOf(_shares(bill, 131000)), 131000);
    });

    test('extras can be split equally instead', () {
      const bill = ItemizedSpec(
        items: [
          BillLine(name: '', amount: 30000, memberIds: ['a']),
          BillLine(name: '', amount: 10000, memberIds: ['b']),
        ],
        tip: 2000,
        spread: ExtrasSpread.equal,
      );
      expect(_shares(bill, 42000), {'a': 31000, 'b': 11000});
    });

    test('problems: no items, an item nobody had, a changed amount', () {
      expect(const ItemizedSpec(items: []).problem(null), isA<NoItems>());
      expect(
        const ItemizedSpec(
          items: [BillLine(name: '', amount: 100, memberIds: [])],
        ).problem(null),
        isA<ItemWithoutPeople>(),
      );
      expect((restaurant.problem(400000)! as BillTotalDiffers).total, 440000);
      expect(restaurant.problem(440000), isNull);
    });

    test('the restaurant with drinks as a shared item gives the same', () {
      final withShared = ItemizedSpec(
        items: restaurant.items.take(4).toList(),
        shared: const [BillLine(name: 'Drinks', amount: 80000, memberIds: [])],
        sharedWith: sharedWithFor(restaurant.items.take(4).toList(), _order),
        taxBp: 1000,
      );
      expect(withShared.sharedWith, ['a', 'b', 'c', 'd']);
      expect(withShared.total, 440000);
      expect(_shares(withShared, 440000), _shares(restaurant, 440000));
    });

    test('shared items alone are split across the whole group', () {
      const order = ['a', 'b'];
      expect(sharedWithFor(const [], order), order);
      final bill = ItemizedSpec(
        items: const [],
        shared: const [BillLine(name: 'Pizza', amount: 2000, memberIds: [])],
        sharedWith: sharedWithFor(const [], order),
      );
      expect(bill.problem(null), isNull);
      expect(bill.shares(amount: 2000, order: order, payers: const ['a']), {
        'a': 1000,
        'b': 1000,
      });
    });

    test('older bills without shared items still read back', () {
      final json = Map.of(restaurant.toJson())
        ..remove('shared')
        ..remove('sharedWith');
      final back =
          SplitSpec.fromJson(SplitMode.itemized, json)! as ItemizedSpec;
      expect(back.shared, isEmpty);
      expect(_shares(back, 440000), _shares(restaurant, 440000));
    });

    test('reads back from splitInput the same', () {
      final back =
          SplitSpec.fromJson(SplitMode.itemized, restaurant.toJson())!
              as ItemizedSpec;
      expect(back.toJson(), restaurant.toJson());
      expect(_shares(back, 440000), _shares(restaurant, 440000));
    });
  });
}
