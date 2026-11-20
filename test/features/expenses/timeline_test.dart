import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/timeline.dart';
import 'package:settle/features/settlements/domain/settlement.dart';

DateTime _day(int d, [int hour = 12]) => DateTime(2026, 11, d, hour);

/// [payer] paid [amount]; split equally with [other].
Expense _e(
  String id,
  DateTime date, {
  String payer = 'a',
  String other = 'b',
  int amount = 500,
  bool deleted = false,
}) => Expense(
  id: id,
  title: id,
  amount: amount,
  date: date,
  createdBy: 'u',
  createdAt: date,
  updatedAt: date,
  splitMode: SplitMode.equal,
  payers: {payer: amount},
  shares: {payer: amount ~/ 2, other: amount - amount ~/ 2},
  deleted: deleted,
);

Settlement _s(
  DateTime at,
  int amount, {
  String from = 'b',
  String to = 'a',
  bool confirmed = true,
}) => Settlement(
  id: 's${at.day}$amount',
  from: from,
  to: to,
  amount: amount,
  status: confirmed ? SettlementStatus.confirmed : SettlementStatus.pending,
  createdBy: 'u',
  createdAt: at,
);

void main() {
  group('settledExpenseIds', () {
    test('a full payment settles the expenses before it', () {
      expect(settledExpenseIds([_e('dinner', _day(1))], [_s(_day(2), 250)]), {
        'dinner',
      });
    });

    test('expenses after the settled moment stay open', () {
      expect(
        settledExpenseIds(
          [_e('dinner', _day(1)), _e('chai', _day(3))],
          [_s(_day(2), 250)],
        ),
        {'dinner'},
      );
    });

    test('pending and part payments settle nothing', () {
      expect(
        settledExpenseIds(
          [_e('dinner', _day(1))],
          [_s(_day(2), 250, confirmed: false)],
        ),
        isEmpty,
      );
      expect(
        settledExpenseIds([_e('dinner', _day(1))], [_s(_day(2), 100)]),
        isEmpty,
      );
    });

    test('an expense back-dated before the payment reopens everything', () {
      expect(
        settledExpenseIds(
          [_e('dinner', _day(1)), _e('taxi', _day(1, 9))],
          [_s(_day(2), 250)],
        ),
        isEmpty,
      );
    });

    test('a later full settle-up covers everything before it', () {
      expect(
        settledExpenseIds(
          [_e('dinner', _day(1)), _e('chai', _day(3))],
          [_s(_day(2), 250), _s(_day(4), 250)],
        ),
        {'dinner', 'chai'},
      );
    });

    test('deleted expenses are ignored', () {
      expect(
        settledExpenseIds(
          [_e('dinner', _day(1)), _e('oops', _day(1, 13), deleted: true)],
          [_s(_day(2), 250)],
        ),
        {'dinner'},
      );
    });
  });

  test('timelineByDay: newest day and item first, payments included, '
      'pending and deleted left out', () {
    final days = timelineByDay(
      [
        _e('dinner', _day(1)),
        _e('oops', _day(1, 14), deleted: true),
        _e('chai', _day(3, 20)),
      ],
      [_s(_day(3, 18), 250), _s(_day(3, 19), 50, confirmed: false)],
    );
    expect([for (final (day, _) in days) day.day], [3, 1]);
    final today = days.first.$2;
    expect(today, hasLength(2));
    expect((today.first as ExpenseItem).expense.id, 'chai');
    expect((today.first as ExpenseItem).settled, isFalse);
    expect(today.last, isA<PaymentItem>());
    final dinner = days.last.$2.single as ExpenseItem;
    expect(dinner.expense.id, 'dinner');
    expect(dinner.settled, isTrue);
  });
}
