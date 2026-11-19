// Firestore docs → domain objects. Stored data can be wrong (old app
// version, bad write); it must be rejected, never read as money.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/activity/data/activity_log.dart';
import 'package:settle/features/activity/domain/activity.dart';
import 'package:settle/features/expenses/data/expense_mapper.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/groups/data/group_mapper.dart';
import 'package:settle/features/settlements/data/settlement_repository.dart';
import 'package:settle/features/settlements/domain/settlement.dart';

void main() {
  final when = Timestamp.fromDate(DateTime.utc(2026, 11, 19));

  Map<String, Object?> expenseDoc([
    Map<String, Object?> overrides = const {},
  ]) => {
    'title': 'Chai',
    'amount': 100000,
    'date': when,
    'createdBy': 'uid-ali',
    'createdAt': when,
    'updatedAt': when,
    'deleted': false,
    'splitMode': 'equal',
    'payers': {'ali': 100000},
    'shares': {'ali': 50000, 'sara': 50000},
    'splitInput': {
      'participants': ['ali', 'sara'],
    },
    'note': '',
    ...overrides,
  };

  group('expenses', () {
    test('round-trips through the draft fields', () {
      final e = expenseFromMap('e1', expenseDoc())!;
      expect(e.amount, 100000);
      expect(e.splitMode, SplitMode.equal);
      expect(e.date, when.toDate());
      expect(e.isBalanced, isTrue);
      expect(expenseFields(ExpenseDraft.of(e))['shares'], e.shares);
    });

    test('non-int money is rejected, not rounded', () {
      expect(expenseFromMap('e', expenseDoc({'amount': 1000.5})), isNull);
      expect(
        expenseFromMap(
          'e',
          expenseDoc({
            'payers': {'ali': 99.9},
          }),
        ),
        isNull,
      );
      expect(expenseFromMap('e', expenseDoc({'shares': null})), isNull);
    });

    test('shares that do not add up are flagged, not trusted', () {
      final e = expenseFromMap(
        'e',
        expenseDoc({
          'shares': {'ali': 50000, 'sara': 40000},
        }),
      )!;
      expect(e.isBalanced, isFalse);
      expect(() => e.toLedger().validate(), throwsA(isA<MoneyException>()));
    });

    test('pending server timestamps (offline) still read', () {
      final e = expenseFromMap('e', expenseDoc({'createdAt': null}))!;
      expect(e.createdAt, isA<DateTime>());
    });
  });

  test('settlements: unknown status or bad amount is skipped', () {
    final ok = settlementFromMap('s', {
      'from': 'bilal',
      'to': 'ali',
      'amount': 30000,
      'status': 'pending',
      'createdBy': 'uid-bilal',
      'createdAt': when,
      'confirmedAt': null,
    })!;
    expect(ok.status, SettlementStatus.pending);
    expect(ok.isConfirmed, isFalse);
    expect(
      settlementFromMap('s', {'amount': 30000, 'status': 'maybe'}),
      isNull,
    );
    expect(
      settlementFromMap('s', {'amount': '300', 'status': 'pending'}),
      isNull,
    );
  });

  test('members: placeholder has no uid', () {
    final m = memberFromMap('m', {
      'displayName': 'Fatima',
      'uid': null,
      'joinedAt': when,
      'active': true,
      'paymentMethods': [
        {
          'id': 'p1',
          'name': 'NayaPay',
          'accountTitle': 'F',
          'accountNumber': '03xx',
          'preferred': true,
        },
      ],
    });
    expect(m.isPlaceholder, isTrue);
    expect(m.paymentMethods.single.name, 'NayaPay');
  });

  test('activity from a newer app version (unknown type) is skipped', () {
    expect(activityFromMap('a', {'type': 'somethingNew'}), isNull);
    expect(
      activityFromMap('a', {
        'type': 'expenseAdded',
        'actorMemberId': 'm',
      })!.type,
      ActivityType.expenseAdded,
    );
  });
}
