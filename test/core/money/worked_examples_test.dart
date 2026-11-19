// The four worked examples from PLAN.md §4, plus the core scene from §2.
// If one of these fails, money is wrong. Don't "fix" the expected values.
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';

/// Rupees to paisa, for readable test values.
int rs(int rupees) => rupees * 100;

const ali = 'ali', sara = 'sara', bilal = 'bilal', hamza = 'hamza';
const fatima = 'fatima';
const friends = [ali, sara, bilal, hamza, fatima]; // join order

void main() {
  group('Chai (PLAN.md §2 and §4)', () {
    // Ali pays Rs 1000 for chai, Sara pays Rs 500 for fries, 5 people equal.
    final chai = LedgerExpense(
      amount: rs(1000),
      payers: {ali: rs(1000)},
      shares: splitEqual(
        amount: rs(1000),
        participants: friends,
        payers: [ali],
      ),
    );
    final fries = LedgerExpense(
      amount: rs(500),
      payers: {sara: rs(500)},
      shares: splitEqual(
        amount: rs(500),
        participants: friends,
        payers: [sara],
      ),
    );
    final nets = netBalances(expenses: [chai, fries], members: friends);

    test('everyone owes Rs 300', () {
      final owed = <String, int>{};
      for (final e in [chai, fries]) {
        e.shares.forEach((id, p) => owed[id] = (owed[id] ?? 0) + p);
      }
      expect(owed.values, everyElement(rs(300)));
    });

    test('nets: A +700, B +200, C/D/E −300', () {
      expect(nets, {
        ali: rs(700),
        sara: rs(200),
        bilal: -rs(300),
        hamza: -rs(300),
        fatima: -rs(300),
      });
    });

    test('settle-up matches the core scene', () {
      // Same payments as PLAN.md §2. Order isn't part of the rule: the
      // algorithm pays the largest creditor first (Sara's 200 before Ali's
      // last 100), and the settle-up screen sorts rows itself (DESIGN.md §11).
      expect(
        simplifyDebts(nets, order: friends),
        unorderedEquals([
          Transfer(from: bilal, to: ali, amount: rs(300)),
          Transfer(from: hamza, to: ali, amount: rs(300)),
          Transfer(from: fatima, to: ali, amount: rs(100)),
          Transfer(from: fatima, to: sara, amount: rs(200)),
        ]),
      );
    });
  });

  test('Gaming zone: exact split → B pays A 500, C pays A 200', () {
    const a = 'a', b = 'b', c = 'c', d = 'd', e = 'e';
    final expense = LedgerExpense(
      amount: rs(1000),
      payers: {a: rs(1000)},
      shares: splitExact(
        amount: rs(1000),
        amounts: {a: rs(300), b: rs(500), c: rs(200), d: 0, e: 0},
      ),
    );
    final nets = netBalances(expenses: [expense]);
    expect(nets, {a: rs(700), b: -rs(500), c: -rs(200), d: 0, e: 0});
    expect(simplifyDebts(nets, order: [a, b, c, d, e]), [
      Transfer(from: b, to: a, amount: rs(500)),
      Transfer(from: c, to: a, amount: rs(200)),
    ]);
  });

  test('Restaurant: itemized + 10% tax → Ali +2530, Sara −880, Bilal −880, '
      'Hamza −770', () {
    const diners = [ali, sara, bilal, hamza];
    final items = [
      BillItem(amount: rs(1500), memberIds: [ali]), // steak
      BillItem(amount: rs(600), memberIds: [sara]),
      BillItem(amount: rs(600), memberIds: [bilal]),
      BillItem(amount: rs(500), memberIds: [hamza]),
      BillItem(amount: rs(800), memberIds: diners), // shared drinks
    ];
    final subtotal = items.fold<int>(0, (sum, i) => sum + i.amount);
    final tax = percentOf(amount: subtotal, basisPoints: 1000); // 10%
    final total = subtotal + tax;

    final shares = splitItemized(
      items: items,
      extras: tax,
      order: diners,
      payers: [ali],
    );
    expect(sumOf(shares), total);

    final nets = netBalances(
      expenses: [
        LedgerExpense(amount: total, payers: {ali: total}, shares: shares),
      ],
    );
    expect(nets, {
      ali: rs(2530),
      sara: -rs(880),
      bilal: -rs(880),
      hamza: -rs(770),
    });
  });

  test('Rounding: Rs 1000 among 3 → 333.34 / 333.33 / 333.33', () {
    final shares = splitEqual(
      amount: rs(1000),
      participants: ['a', 'b', 'c'],
      payers: ['a'],
    );
    expect(shares, {'a': 33334, 'b': 33333, 'c': 33333});
    expect(sumOf(shares), rs(1000));
    expect(shares.values.map(formatRupees), [
      'Rs 333.34',
      'Rs 333.33',
      'Rs 333.33',
    ]);
  });
}
