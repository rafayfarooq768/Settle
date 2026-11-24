import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/activity/data/activity_repository.dart';
import 'package:settle/features/activity/domain/activity.dart';
import 'package:settle/features/expenses/data/expense_repository.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';

/// Saving expenses (PLAN.md §3 items 6–7) against an in-memory Firestore.
void main() {
  late FakeFirebaseFirestore db;
  late ExpenseRepository repo;
  const g = 'g1';
  final day = DateTime(2026, 11, 20, 19, 30);

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ExpenseRepository(db);
  });

  // PLAN.md §2: Ali pays Rs 1000 for chai, five people, equal.
  ExpenseDraft chai({int amount = 100000, String title = 'Chai'}) =>
      ExpenseDraft(
        title: title,
        amount: amount,
        date: day,
        splitMode: SplitMode.equal,
        payers: {'ali': amount},
        shares: splitEqual(
          amount: amount,
          participants: ['ali', 'sara', 'bilal', 'hamza', 'fatima'],
          payers: ['ali'],
        ),
        splitInput: const {
          'participants': ['ali', 'sara', 'bilal', 'hamza', 'fatima'],
        },
        note: 'At the dhaba',
      );

  Future<String> add(ExpenseDraft draft) =>
      repo.add(groupId: g, uid: 'u-ali', actorMemberId: 'ali', draft: draft);
  Future<List<Expense>> all() => repo.watch(g).first;
  Future<Expense> one(String id) async =>
      (await all()).firstWhere((e) => e.id == id);
  Future<List<Activity>> log() => ActivityRepository(db).watch(g).first;

  group('add', () {
    test('saves every field exactly, in integer paisa', () async {
      final id = await add(chai());
      final e = await one(id);
      expect(e.title, 'Chai');
      expect(e.amount, 100000);
      expect(e.date, day);
      expect(e.splitMode, SplitMode.equal);
      expect(e.payers, {'ali': 100000});
      expect(e.shares.values.every((v) => v == 20000), isTrue);
      expect(e.note, 'At the dhaba');
      expect(e.createdBy, 'u-ali');
      expect(e.deleted, isFalse);
      expect(e.splitInput['participants'], hasLength(5));

      final raw = (await db.doc('groups/$g/expenses/$id').get()).data()!;
      expect(raw['amount'], isA<int>());
      expect((raw['shares'] as Map).values, everyElement(isA<int>()));
    });

    test('odd paisa still sum exactly (Rs 1000 among 3)', () async {
      final id = await add(
        ExpenseDraft(
          title: 'Fries',
          amount: 100000,
          date: day,
          splitMode: SplitMode.equal,
          payers: const {'a': 100000},
          shares: splitEqual(
            amount: 100000,
            participants: ['a', 'b', 'c'],
            payers: ['a'],
          ),
        ),
      );
      final e = await one(id);
      expect(e.shares, {'a': 33334, 'b': 33333, 'c': 33333});
      expect(e.isBalanced, isTrue);
    });

    test('is logged with its amount', () async {
      final id = await add(chai());
      final entry = (await log()).single;
      expect(entry.type, ActivityType.expenseAdded);
      expect(entry.actorMemberId, 'ali');
      expect(entry.targetId, id);
      expect(entry.summary, 'Chai');
      expect(entry.after!['amount'], 100000);
    });

    test('several payers are saved as they are', () async {
      final id = await add(
        ExpenseDraft(
          title: 'Dinner',
          amount: 150000,
          date: day,
          splitMode: SplitMode.equal,
          payers: const {'ali': 100000, 'sara': 50000},
          shares: const {'ali': 50000, 'sara': 50000, 'bilal': 50000},
        ),
      );
      expect((await one(id)).payers, {'ali': 100000, 'sara': 50000});
    });
  });

  group('refuses to save money that does not add up', () {
    Future<void> expectRefused(ExpenseDraft draft) async {
      await expectLater(add(draft), throwsA(isA<MoneyException>()));
      expect(await all(), isEmpty, reason: 'nothing may be written');
      expect(await log(), isEmpty);
    }

    ExpenseDraft draft({
      String title = 'Chai',
      int amount = 30000,
      Map<String, int> payers = const {'a': 30000},
      Map<String, int> shares = const {'a': 15000, 'b': 15000},
    }) => ExpenseDraft(
      title: title,
      amount: amount,
      date: day,
      splitMode: SplitMode.exact,
      payers: payers,
      shares: shares,
    );

    test('shares one paisa short', () async {
      await expectRefused(draft(shares: const {'a': 15000, 'b': 14999}));
    });
    test('shares one paisa over', () async {
      await expectRefused(draft(shares: const {'a': 15000, 'b': 15001}));
    });
    test('payers not adding up', () async {
      await expectRefused(draft(payers: const {'a': 20000}));
    });
    test('a zero amount', () async {
      await expectRefused(
        draft(amount: 0, payers: const {'a': 0}, shares: const {'a': 0}),
      );
    });
    test('a negative share', () async {
      await expectRefused(draft(shares: const {'a': 40000, 'b': -10000}));
    });
    test('no shares at all', () async {
      await expectRefused(draft(shares: const {}));
    });
    test('a blank title', () async {
      await expectRefused(draft(title: '   '));
    });
  });

  group('edit', () {
    test('changes the expense and logs before and after', () async {
      final id = await add(chai());
      final before = await one(id);
      await repo.edit(
        groupId: g,
        actorMemberId: 'sara',
        before: before,
        draft: chai(amount: 120000, title: 'Chai and samosa'),
      );
      final after = await one(id);
      expect(after.amount, 120000);
      expect(after.title, 'Chai and samosa');
      expect(after.createdBy, 'u-ali', reason: 'the creator never changes');
      expect(after.isBalanced, isTrue);

      final entry = (await log()).firstWhere(
        (a) => a.type == ActivityType.expenseEdited,
      );
      expect(entry.actorMemberId, 'sara');
      expect(entry.before!['amount'], 100000);
      expect(entry.after!['amount'], 120000);
    });

    test('an edit that does not add up changes nothing', () async {
      final id = await add(chai());
      final before = await one(id);
      final bad = ExpenseDraft(
        title: 'Chai',
        amount: 120000,
        date: day,
        splitMode: SplitMode.exact,
        payers: const {'ali': 120000},
        shares: const {'ali': 100000},
      );
      await expectLater(
        repo.edit(groupId: g, actorMemberId: 'ali', before: before, draft: bad),
        throwsA(isA<MoneyException>()),
      );
      expect((await one(id)).amount, 100000);
    });

    test('Undo of an edit puts the old version back', () async {
      final id = await add(chai());
      final original = await one(id);
      await repo.edit(
        groupId: g,
        actorMemberId: 'ali',
        before: original,
        draft: chai(amount: 120000),
      );
      await repo.edit(
        groupId: g,
        actorMemberId: 'ali',
        before: await one(id),
        draft: ExpenseDraft.of(original),
      );
      final back = await one(id);
      expect(back.amount, original.amount);
      expect(back.shares, original.shares);
      expect(back.note, original.note);
    });
  });

  group('delete', () {
    test('is soft: the expense stays, marked deleted', () async {
      final id = await add(chai());
      await repo.setDeleted(
        groupId: g,
        actorMemberId: 'ali',
        expense: await one(id),
        deleted: true,
      );
      expect((await db.doc('groups/$g/expenses/$id').get()).exists, isTrue);
      expect((await one(id)).deleted, isTrue);
      final entry = (await log()).firstWhere(
        (a) => a.type == ActivityType.expenseDeleted,
      );
      expect(entry.before!['amount'], 100000);
    });

    test('Undo restores it', () async {
      final id = await add(chai());
      await repo.setDeleted(
        groupId: g,
        actorMemberId: 'ali',
        expense: await one(id),
        deleted: true,
      );
      await repo.setDeleted(
        groupId: g,
        actorMemberId: 'ali',
        expense: await one(id),
        deleted: false,
      );
      expect((await one(id)).deleted, isFalse);
      expect(
        (await log()).map((a) => a.type),
        containsAll([
          ActivityType.expenseDeleted,
          ActivityType.expenseRestored,
        ]),
      );
    });
  });

  group('reading', () {
    test('newest date first', () async {
      Future<void> on(DateTime date, String title) => add(
        ExpenseDraft(
          title: title,
          amount: 100,
          date: date,
          splitMode: SplitMode.exact,
          payers: const {'a': 100},
          shares: const {'a': 100},
        ),
      );
      await on(DateTime(2026, 11, 18), 'Old');
      await on(DateTime(2026, 11, 22), 'New');
      await on(DateTime(2026, 11, 20), 'Middle');
      expect([for (final e in await all()) e.title], ['New', 'Middle', 'Old']);
    });

    test('a broken doc is skipped, the rest still load', () async {
      await add(chai());
      await db.collection('groups/$g/expenses').add({
        'title': 'Broken',
        'amount': 100.5,
        'date': DateTime(2026, 11, 21),
        'payers': {'a': 100.5},
        'shares': {'a': 100.5},
      });
      expect([for (final e in await all()) e.title], ['Chai']);
    });

    test(
      'a doc whose shares do not add up loads but is not balanced',
      () async {
        await db.collection('groups/$g/expenses').add({
          'title': 'Tampered',
          'amount': 1000,
          'date': DateTime(2026, 11, 21),
          'payers': {'a': 1000},
          'shares': {'a': 900},
        });
        final e = (await all()).single;
        expect(e.isBalanced, isFalse);
      },
    );

    test('each group only sees its own expenses', () async {
      await add(chai());
      await ExpenseRepository(db).add(
        groupId: 'other',
        uid: 'u-x',
        actorMemberId: 'x',
        draft: chai(title: 'Elsewhere'),
      );
      expect([for (final e in await all()) e.title], ['Chai']);
    });
  });
}
