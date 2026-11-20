import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';

Expense _expense(String id, ExpenseDraft d, {bool deleted = false}) => Expense(
  id: id,
  title: d.title,
  amount: d.amount,
  date: d.date,
  createdBy: 'u1',
  createdAt: d.date,
  updatedAt: d.date,
  splitMode: d.splitMode,
  payers: d.payers,
  shares: d.shares,
  deleted: deleted,
);

void main() {
  final day = DateTime(2026, 11, 20, 18);

  group('equalDraft', () {
    test('Rs 1000 among 3, paid by A: payer gets the extra paisa', () {
      final d = equalDraft(
        title: '  Chai ',
        amount: 100000,
        date: day,
        payerId: 'a',
        participants: ['b', 'a', 'c'],
      );
      expect(d.title, 'Chai');
      expect(d.splitMode, SplitMode.equal);
      expect(d.payers, {'a': 100000});
      expect(d.shares, {'a': 33334, 'b': 33333, 'c': 33333});
      expect(sumOf(d.shares), 100000);
      expect(d.splitInput['participants'], ['b', 'a', 'c']);
    });

    test('the payer need not be a participant', () {
      final d = equalDraft(
        title: 'Gift',
        amount: 50000,
        date: day,
        payerId: 'a',
        participants: ['b', 'c'],
      );
      expect(d.shares, {'b': 25000, 'c': 25000});
    });

    test('nobody ticked is refused', () {
      expect(
        () => equalDraft(
          title: 'x',
          amount: 100,
          date: day,
          payerId: 'a',
          participants: [],
        ),
        throwsA(isA<MoneyException>()),
      );
    });
  });

  group('myPart', () {
    // The core scene: Ali pays Rs 1000 for chai, 5 people equal.
    final chai = _expense(
      'e1',
      equalDraft(
        title: 'Chai',
        amount: 100000,
        date: day,
        payerId: 'ali',
        participants: ['ali', 'sara', 'bilal', 'hamza', 'fatima'],
      ),
    );

    test('payer lent everyone else their share', () {
      expect((myPart(chai, 'ali') as Lent).amount, 80000);
    });

    test('a participant owes their share', () {
      expect((myPart(chai, 'sara') as Owe).amount, 20000);
    });

    test('someone not in it is not involved', () {
      expect(myPart(chai, 'zara'), isA<NotInvolved>());
    });

    test('paying only for yourself is even', () {
      final solo = _expense(
        'e2',
        equalDraft(
          title: 'Snack',
          amount: 30000,
          date: day,
          payerId: 'ali',
          participants: ['ali'],
        ),
      );
      expect(myPart(solo, 'ali'), isA<Even>());
    });
  });

  test('byDay: newest day first, deleted left out', () {
    ExpenseDraft at(DateTime d) => equalDraft(
      title: 't',
      amount: 100,
      date: d,
      payerId: 'a',
      participants: ['a'],
    );
    final days = byDay([
      _expense('1', at(DateTime(2026, 11, 20, 9))),
      _expense('2', at(DateTime(2026, 11, 18, 9))),
      _expense('3', at(DateTime(2026, 11, 20, 8))),
      _expense('4', at(DateTime(2026, 11, 19, 9)), deleted: true),
    ]);
    expect(days.map((d) => d.$1), [
      DateTime(2026, 11, 20),
      DateTime(2026, 11, 18),
    ]);
    expect(days.first.$2.map((e) => e.id), ['1', '3']);
  });
}
