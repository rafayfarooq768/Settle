import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/expenses/domain/duplicate_guard.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';

final _now = DateTime(2026, 11, 20, 21, 0);

Expense _expense({
  String id = 'e1',
  int amount = 100000,
  Map<String, int> shares = const {'a': 50000, 'b': 50000},
  Duration ago = const Duration(minutes: 2),
  bool deleted = false,
}) => Expense(
  id: id,
  title: 'Chai',
  amount: amount,
  date: _now,
  createdBy: 'u1',
  createdAt: _now.subtract(ago),
  updatedAt: _now.subtract(ago),
  splitMode: SplitMode.equal,
  payers: {'a': amount},
  shares: shares,
  deleted: deleted,
);

ExpenseDraft _draft({
  int amount = 100000,
  Map<String, int> shares = const {'a': 50000, 'b': 50000},
  Map<String, int> payers = const {'b': 100000},
}) => ExpenseDraft(
  title: 'Tea',
  amount: amount,
  date: _now,
  splitMode: SplitMode.exact,
  payers: payers,
  shares: shares,
);

void main() {
  test('same amount and people 2 minutes ago is a duplicate', () {
    // Who paid and the title don't matter: a friend may add it too.
    expect(findDuplicate([_expense()], _draft(), now: _now)?.id, 'e1');
  });

  test('a different amount is not', () {
    expect(findDuplicate([_expense()], _draft(amount: 90000), now: _now), null);
  });

  test('different people are not', () {
    final draft = _draft(shares: {'a': 50000, 'c': 50000});
    expect(findDuplicate([_expense()], draft, now: _now), null);
  });

  test('someone with a zero share is not part of it', () {
    final draft = _draft(shares: {'a': 50000, 'b': 50000, 'c': 0});
    expect(findDuplicate([_expense()], draft, now: _now)?.id, 'e1');
  });

  test('older than the window, or deleted, is not', () {
    expect(
      findDuplicate(
        [_expense(ago: const Duration(minutes: 11))],
        _draft(),
        now: _now,
      ),
      null,
    );
    expect(findDuplicate([_expense(deleted: true)], _draft(), now: _now), null);
  });

  test('picks the newest match', () {
    final older = _expense(id: 'old', ago: const Duration(minutes: 8));
    final newer = _expense(id: 'new', ago: const Duration(minutes: 1));
    expect(findDuplicate([older, newer], _draft(), now: _now)?.id, 'new');
  });
}
