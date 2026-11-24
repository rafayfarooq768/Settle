import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/firestore/firestore_provider.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/balances/ui/balances_providers.dart';
import 'package:settle/features/expenses/data/expense_repository.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';
import 'package:settle/features/groups/data/group_repository.dart';
import 'package:settle/features/settlements/data/settlement_repository.dart';

/// PLAN.md §2 from start to finish, through the real repositories and the
/// same providers the screens use: create a group, add the friends, add
/// chai and fries, read the settle-up list, pay until everyone is settled.
void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late String groupId;
  late Map<String, String> ids; // name → memberId

  setUp(() async {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );
    final groups = GroupRepository(db);
    groupId = await groups.createGroup(
      uid: 'u-ali',
      name: 'Chai',
      type: 'Friends',
      creatorName: 'Ali',
    );
    final aliId = (await groups.watchMembers(groupId).first).single.id;
    ids = {'Ali': aliId};
    for (final name in ['Sara', 'Bilal', 'Hamza', 'Fatima']) {
      ids[name] = await groups.addPlaceholder(
        groupId: groupId,
        actorMemberId: aliId,
        name: name,
      );
    }
  });

  tearDown(() => container.dispose());

  Future<Map<String, int>> nets() async {
    final sub = container.listen(groupNetsProvider(groupId), (_, _) {});
    try {
      for (var i = 0; i < 50; i++) {
        final value = sub.read();
        if (value is AsyncData<Map<String, int>>) {
          // Let any write still settling reach the listeners first.
          await Future<void>.delayed(Duration.zero);
          final latest = sub.read();
          if (latest.hasValue) {
            return {
              for (final MapEntry(:key, :value) in ids.entries)
                key: latest.requireValue[value] ?? 0,
            };
          }
        }
        if (value.hasError) throw value.error!;
        await Future<void>.delayed(Duration.zero);
      }
      fail('balances never loaded');
    } finally {
      sub.close();
    }
  }

  List<String> settleUp(Map<String, int> byName) => [
    for (final t in simplifyDebts(
      byName,
      order: ['Ali', 'Sara', 'Bilal', 'Hamza', 'Fatima'],
    ))
      '${t.from} pays ${t.to} ${formatRupees(t.amount)}',
  ];

  Future<void> addEqual(String title, String payer, int rupees) {
    final amount = rupees * 100;
    final everyone = [for (final n in ids.keys) ids[n]!];
    return ExpenseRepository(db).add(
      groupId: groupId,
      uid: 'u-ali',
      actorMemberId: ids['Ali']!,
      draft: ExpenseDraft(
        title: title,
        amount: amount,
        date: DateTime(2026, 11, 20),
        splitMode: SplitMode.equal,
        payers: {ids[payer]!: amount},
        shares: splitEqual(
          amount: amount,
          participants: everyone,
          payers: [ids[payer]!],
        ),
      ),
    );
  }

  test('chai and fries: everyone sees the same settle-up list', () async {
    await addEqual('Chai', 'Ali', 1000);
    await addEqual('Fries', 'Sara', 500);

    final byName = await nets();
    expect(byName, {
      'Ali': 70000,
      'Sara': 20000,
      'Bilal': -30000,
      'Hamza': -30000,
      'Fatima': -30000,
    });
    expect(byName.values.reduce((a, b) => a + b), 0);
    // PLAN.md §2 lists Fatima paying Ali 100 and Sara 200; any minimum
    // list settles everyone in at most n − 1 payments.
    final list = settleUp(byName);
    expect(list, hasLength(lessThanOrEqualTo(4)));
    expect(list, contains('Bilal pays Ali Rs 300'));
  });

  test('a pending "I paid" changes nothing until it is confirmed', () async {
    await addEqual('Chai', 'Ali', 1000);
    final payments = SettlementRepository(db);
    final id = await payments.record(
      groupId: groupId,
      uid: 'u-bilal',
      actorMemberId: ids['Bilal']!,
      from: ids['Bilal']!,
      to: ids['Ali']!,
      amount: 20000,
    );
    expect((await nets())['Bilal'], -20000);

    final pending = (await payments.watch(groupId).first).single;
    expect(pending.id, id);
    await payments.confirm(
      groupId: groupId,
      actorMemberId: ids['Ali']!,
      settlement: pending,
    );
    expect((await nets())['Bilal'], 0);
    expect((await nets())['Ali'], 60000);
  });

  test(
    'deleting an expense takes it out of the balances, Undo puts it back',
    () async {
      await addEqual('Chai', 'Ali', 1000);
      await addEqual('Fries', 'Sara', 500);
      final repo = ExpenseRepository(db);
      final fries = (await repo.watch(groupId).first).firstWhere(
        (e) => e.title == 'Fries',
      );

      await repo.setDeleted(
        groupId: groupId,
        actorMemberId: ids['Ali']!,
        expense: fries,
        deleted: true,
      );
      expect((await nets())['Sara'], -20000);

      await repo.setDeleted(
        groupId: groupId,
        actorMemberId: ids['Ali']!,
        expense: fries,
        deleted: false,
      );
      expect((await nets())['Sara'], 20000);
    },
  );

  test('paying the whole list settles everyone', () async {
    await addEqual('Chai', 'Ali', 1000);
    await addEqual('Fries', 'Sara', 500);
    final payments = SettlementRepository(db);
    final transfers = simplifyDebts(await nets());

    for (final (i, t) in transfers.indexed) {
      final before = await nets();
      final last = i == transfers.length - 1;
      expect(
        settlesEveryone(
          {for (final e in before.entries) ids[e.key]!: e.value},
          from: ids[t.from]!,
          to: ids[t.to]!,
          amount: t.amount,
        ),
        last,
        reason: 'only the last payment says "Shabash, sab settle ho gaya"',
      );
      await payments.record(
        groupId: groupId,
        uid: 'u-ali',
        actorMemberId: ids['Ali']!,
        from: ids[t.from]!,
        to: ids[t.to]!,
        amount: t.amount,
        confirmed: true,
      );
    }
    expect((await nets()).values, everyElement(0));
  });

  test('a tampered expense is left out instead of breaking balances', () async {
    await addEqual('Chai', 'Ali', 1000);
    await db.collection('groups/$groupId/expenses').add({
      'title': 'Tampered',
      'amount': 100000,
      'date': DateTime(2026, 11, 21),
      'payers': {ids['Hamza']: 100000},
      'shares': {ids['Hamza']: 1},
      'deleted': false,
    });
    final byName = await nets();
    expect(byName['Hamza'], -20000);
    expect(byName.values.reduce((a, b) => a + b), 0);
  });
}
