import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_search.dart';
import 'package:settle/features/expenses/domain/monthly_summary.dart';

Expense _e(
  String id, {
  String title = 'Chai',
  String note = '',
  int amount = 90000,
  DateTime? date,
  Map<String, int>? payers,
  Map<String, int>? shares,
  bool deleted = false,
}) {
  final d = date ?? DateTime(2026, 11, 20);
  return Expense(
    id: id,
    title: title,
    note: note,
    amount: amount,
    date: d,
    createdBy: 'u1',
    createdAt: d,
    updatedAt: d,
    splitMode: SplitMode.equal,
    payers: payers ?? {'a': amount},
    shares: shares ?? {'a': amount ~/ 3, 'b': amount ~/ 3, 'c': amount ~/ 3},
    deleted: deleted,
  );
}

void main() {
  group('search', () {
    test('matches the title or note, any case', () {
      expect(matchesSearch(_e('1', title: 'Chai'), query: 'chai'), isTrue);
      expect(
        matchesSearch(_e('1', note: 'Dhaba chai'), query: 'DHABA'),
        isTrue,
      );
      expect(matchesSearch(_e('1', title: 'Fries'), query: 'chai'), isFalse);
    });

    test('an empty query matches everything not deleted', () {
      expect(matchesSearch(_e('1')), isTrue);
      expect(matchesSearch(_e('1', deleted: true)), isFalse);
    });

    test('involves me: paid or has a share', () {
      final e = _e(
        '1',
        amount: 60000,
        payers: {'a': 60000},
        shares: {'b': 30000, 'c': 30000},
      );
      expect(matchesSearch(e, involving: 'a'), isTrue); // paid
      expect(matchesSearch(e, involving: 'b'), isTrue); // share
      expect(matchesSearch(e, involving: 'd'), isFalse);
    });

    test('month filter keeps only that month', () {
      final nov = _e('1', date: DateTime(2026, 11, 3));
      final oct = _e('2', date: DateTime(2026, 10, 30));
      expect(matchesSearch(nov, month: DateTime(2026, 11)), isTrue);
      expect(matchesSearch(oct, month: DateTime(2026, 11)), isFalse);
    });

    test('months with expenses, newest first, no repeats', () {
      final months = expenseMonths([
        _e('1', date: DateTime(2026, 10, 2)),
        _e('2', date: DateTime(2026, 11, 5)),
        _e('3', date: DateTime(2026, 11, 9)),
        _e('4', date: DateTime(2026, 9, 1), deleted: true),
      ]);
      expect(months, [DateTime(2026, 11), DateTime(2026, 10)]);
    });
  });

  group('monthly summary', () {
    test('totals and my share per month, newest first', () {
      final totals = monthlyTotals([
        _e('1', amount: 90000, date: DateTime(2026, 11, 2)),
        _e('2', amount: 30000, date: DateTime(2026, 11, 20)),
        _e('3', amount: 60000, date: DateTime(2026, 10, 15)),
      ], 'b');
      expect(totals.map((t) => t.month), [
        DateTime(2026, 11),
        DateTime(2026, 10),
      ]);
      expect(totals.first.total, 120000);
      expect(totals.first.myShare, 40000);
      expect(totals.last.total, 60000);
      expect(totals.last.myShare, 20000);
    });

    test('deleted and unbalanced expenses are left out', () {
      final totals = monthlyTotals([
        _e('1', deleted: true),
        // Shares don't add up to the amount: bad stored data.
        _e('2', amount: 90000, shares: {'a': 10}),
      ], 'a');
      expect(totals, isEmpty);
    });

    test('a month I am not in has a zero share', () {
      final totals = monthlyTotals([
        _e('1', amount: 60000, payers: {'b': 60000}, shares: {'b': 60000}),
      ], 'a');
      expect(totals.single.myShare, 0);
      expect(totals.single.total, 60000);
    });
  });
}
