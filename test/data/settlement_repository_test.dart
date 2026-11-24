import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/activity/data/activity_repository.dart';
import 'package:settle/features/activity/domain/activity.dart';
import 'package:settle/features/settlements/data/settlement_repository.dart';
import 'package:settle/features/settlements/domain/settlement.dart';

/// The settle flow (PLAN.md §3 item 10) against an in-memory Firestore.
void main() {
  late FakeFirebaseFirestore db;
  late SettlementRepository repo;
  const g = 'g1';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = SettlementRepository(db);
  });

  Future<List<Settlement>> all() => repo.watch(g).first;
  Future<Settlement> one(String id) async =>
      (await all()).firstWhere((s) => s.id == id);
  Future<List<Activity>> log() => ActivityRepository(db).watch(g).first;

  // Bilal owes Ali Rs 300 (PLAN.md §2).
  Future<String> iPaid({int amount = 30000}) => repo.record(
    groupId: g,
    uid: 'u-bilal',
    actorMemberId: 'bilal',
    from: 'bilal',
    to: 'ali',
    amount: amount,
  );

  test('"I paid" is saved pending, so it does not count yet', () async {
    final id = await iPaid();
    final s = await one(id);
    expect(s.from, 'bilal');
    expect(s.to, 'ali');
    expect(s.amount, 30000);
    expect(s.status, SettlementStatus.pending);
    expect(s.isConfirmed, isFalse);
    expect(s.confirmedAt, isNull);
    expect(s.createdBy, 'u-bilal');

    final entry = (await log()).single;
    expect(entry.type, ActivityType.settlementRecorded);
    expect(entry.after!['status'], 'pending');
  });

  test('confirming makes it count, logged as the person paid', () async {
    final id = await iPaid();
    await repo.confirm(
      groupId: g,
      actorMemberId: 'ali',
      settlement: await one(id),
    );
    final s = await one(id);
    expect(s.isConfirmed, isTrue);
    expect(s.confirmedAt, isNotNull);
    final entry = (await log()).firstWhere(
      (a) => a.type == ActivityType.settlementConfirmed,
    );
    expect(entry.actorMemberId, 'ali');
    expect(entry.targetId, id);
  });

  test('"Record payment" is confirmed straight away', () async {
    final id = await repo.record(
      groupId: g,
      uid: 'u-ali',
      actorMemberId: 'ali',
      from: 'bilal',
      to: 'ali',
      amount: 30000,
      confirmed: true,
    );
    final s = await one(id);
    expect(s.isConfirmed, isTrue);
    expect(s.confirmedAt, isNotNull);
    expect((await log()).single.after!['status'], 'confirmed');
  });

  test('cancel or "Not received" removes it and logs what it was', () async {
    final id = await iPaid(amount: 10000);
    await repo.remove(
      groupId: g,
      actorMemberId: 'ali',
      settlement: await one(id),
    );
    expect(await all(), isEmpty);
    final entry = (await log()).firstWhere(
      (a) => a.type == ActivityType.settlementDeleted,
    );
    expect(entry.before, {
      'from': 'bilal',
      'to': 'ali',
      'amount': 10000,
      'status': 'pending',
    });
  });

  test('any amount can be paid, not just what is owed', () async {
    final id = await iPaid(amount: 12345);
    expect((await one(id)).amount, 12345);
  });

  group('refuses', () {
    test('a zero amount', () async {
      await expectLater(iPaid(amount: 0), throwsA(isA<MoneyException>()));
      expect(await all(), isEmpty);
    });
    test('a negative amount', () async {
      await expectLater(iPaid(amount: -100), throwsA(isA<MoneyException>()));
      expect(await all(), isEmpty);
    });
    test('paying yourself', () async {
      await expectLater(
        repo.record(
          groupId: g,
          uid: 'u-ali',
          actorMemberId: 'ali',
          from: 'ali',
          to: 'ali',
          amount: 100,
        ),
        throwsA(isA<MoneyException>()),
      );
      expect(await all(), isEmpty);
      expect(await log(), isEmpty);
    });
  });

  group('reading', () {
    test('a doc with a non-integer amount is skipped', () async {
      await iPaid();
      await db.collection('groups/$g/settlements').add({
        'from': 'x',
        'to': 'y',
        'amount': 99.5,
        'status': 'confirmed',
        'createdAt': DateTime(2026, 11, 20),
      });
      expect(await all(), hasLength(1));
    });

    test('a doc with an unknown status is skipped', () async {
      await db.collection('groups/$g/settlements').add({
        'from': 'x',
        'to': 'y',
        'amount': 100,
        'status': 'refunded',
        'createdAt': DateTime(2026, 11, 20),
      });
      expect(await all(), isEmpty);
    });
  });
}
