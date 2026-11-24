import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/activity/data/activity_repository.dart';
import 'package:settle/features/activity/domain/activity.dart';
import 'package:settle/features/groups/data/group_mapper.dart';
import 'package:settle/features/groups/data/group_repository.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/profile/domain/payment_method.dart';

/// Saving groups, members and join codes (PLAN.md §6, §7) against an
/// in-memory Firestore. Security rules are tested separately
/// (firestore-tests/); these check the app writes the right data.
void main() {
  late FakeFirebaseFirestore db;
  late GroupRepository repo;

  const meezan = PaymentMethod(
    id: 'p1',
    name: 'Meezan Bank',
    accountTitle: 'Ali Khan',
    accountNumber: 'PK00MEZN0001',
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = GroupRepository(db);
  });

  Future<Group> groupOf(String id) async =>
      groupFromMap(id, (await db.doc('groups/$id').get()).data()!);
  Future<List<Member>> members(String id) => repo.watchMembers(id).first;
  Future<Member> member(String groupId, String id) async =>
      (await members(groupId)).firstWhere((m) => m.id == id);
  Future<List<Activity>> activity(String id) =>
      ActivityRepository(db).watch(id).first;
  Future<String> create({String name = 'Chai'}) => repo.createGroup(
    uid: 'u-ali',
    name: name,
    type: 'Friends',
    creatorName: 'Ali',
    paymentMethods: const [meezan],
    phone: '+923001234567',
  );

  group('create', () {
    test('saves the group with its creator as the only member', () async {
      final id = await create();
      final g = await groupOf(id);
      expect(g.name, 'Chai');
      expect(g.type, 'Friends');
      expect(g.createdBy, 'u-ali');
      expect(g.memberUids, ['u-ali']);
      expect(g.currency, 'PKR');

      final me = (await members(id)).single;
      expect(me.displayName, 'Ali');
      expect(me.uid, 'u-ali');
      expect(me.active, isTrue);
      expect(me.phone, '+923001234567');
      expect(me.paymentMethods.single.accountNumber, 'PK00MEZN0001');
    });

    test('its join code points back to the group', () async {
      final id = await create();
      final code = (await groupOf(id)).joinCode;
      expect(code, startsWith('CHAI-'));
      expect(await repo.findGroupByCode(code), id);
      expect(await repo.findGroupByCode(code.toLowerCase()), id);
    });

    test('is logged as created by the creator', () async {
      final id = await create();
      final me = (await members(id)).single;
      final entry = (await activity(id)).single;
      expect(entry.type, ActivityType.groupCreated);
      expect(entry.actorMemberId, me.id);
      expect(entry.summary, 'Chai');
    });
  });

  test('an unknown or malformed code finds nothing', () async {
    await create();
    expect(await repo.findGroupByCode('CHAI-ZZZZZ'), isNull);
    expect(await repo.findGroupByCode('not a code'), isNull);
    expect(await repo.findGroupByCode(''), isNull);
  });

  group('placeholders', () {
    late String id;
    late String meId;
    late String saraId;
    setUp(() async {
      id = await create();
      meId = (await members(id)).single.id;
      saraId = await repo.addPlaceholder(
        groupId: id,
        actorMemberId: meId,
        name: 'Sara',
      );
    });

    test('are added by name, unclaimed and without a phone', () async {
      final sara = await member(id, saraId);
      expect(sara.displayName, 'Sara');
      expect(sara.isPlaceholder, isTrue);
      expect(sara.phone, '');
      expect(sara.paymentMethods, isEmpty);
      expect(sara.active, isTrue);
      final entry = (await activity(id))
          .firstWhere((a) => a.type == ActivityType.placeholderAdded);
      expect(entry.actorMemberId, meId);
      expect(entry.summary, 'Sara');
    });

    test('can be renamed, and the log keeps the old name', () async {
      await repo.renamePlaceholder(
        groupId: id,
        actorMemberId: meId,
        member: await member(id, saraId),
        name: 'Sara B',
      );
      expect((await member(id, saraId)).displayName, 'Sara B');
      final renamed = (await activity(id))
          .firstWhere((a) => a.type == ActivityType.memberRenamed);
      expect(renamed.before, {'displayName': 'Sara'});
      expect(renamed.after, {'displayName': 'Sara B'});
    });

    test('removing hides them but keeps them for history', () async {
      await repo.removePlaceholder(
        groupId: id,
        actorMemberId: meId,
        placeholder: await member(id, saraId),
      );
      final kept = await member(id, saraId);
      expect(kept.active, isFalse);
      expect(kept.displayName, 'Sara');
    });
  });

  group('joining', () {
    late String id;
    late String code;
    late String saraId;
    setUp(() async {
      id = await create();
      code = (await groupOf(id)).joinCode;
      saraId = await repo.addPlaceholder(
        groupId: id,
        actorMemberId: (await members(id)).single.id,
        name: 'Sara',
      );
    });

    test('adds the uid to the group and leaves proof of the code', () async {
      await repo.join(groupId: id, code: code, uid: 'u-sara');
      expect((await groupOf(id)).memberUids, ['u-ali', 'u-sara']);
      final proof = await db.doc('joinCodes/$code/joins/u-sara').get();
      expect(proof.data()!['groupId'], id);
    });

    test('joining twice does not add the uid twice', () async {
      await repo.join(groupId: id, code: code, uid: 'u-sara');
      await repo.join(groupId: id, code: code, uid: 'u-sara');
      expect((await groupOf(id)).memberUids, ['u-ali', 'u-sara']);
    });

    test('a code typed in lower case is saved in its real form', () async {
      await repo.join(groupId: id, code: code.toLowerCase(), uid: 'u-sara');
      final proof = await db.doc('joinCodes/$code/joins/u-sara').get();
      expect(proof.exists, isTrue);
    });

    test('claiming a placeholder keeps its id, so its history', () async {
      await repo.join(groupId: id, code: code, uid: 'u-sara');
      await repo.claimPlaceholder(
        groupId: id,
        placeholder: await member(id, saraId),
        uid: 'u-sara',
        paymentMethods: const [meezan],
        phone: '+923331112222',
      );
      final claimed = await member(id, saraId);
      expect(claimed.uid, 'u-sara');
      expect(claimed.isPlaceholder, isFalse);
      expect(claimed.claimedAt, isNotNull);
      expect(claimed.phone, '+923331112222');
      expect(claimed.paymentMethods.single.name, 'Meezan Bank');
      expect(await members(id), hasLength(2));
      final entry = (await activity(id))
          .firstWhere((a) => a.type == ActivityType.placeholderClaimed);
      expect(entry.actorMemberId, saraId);
    });

    test('"not listed" adds a new member next to the placeholder', () async {
      await repo.join(groupId: id, code: code, uid: 'u-bilal');
      final bilalId = await repo.joinAsNewMember(
        groupId: id,
        uid: 'u-bilal',
        displayName: 'Bilal',
      );
      expect(await members(id), hasLength(3));
      expect((await member(id, bilalId)).uid, 'u-bilal');
      expect((await member(id, saraId)).isPlaceholder, isTrue);
      final entry = (await activity(id))
          .firstWhere((a) => a.type == ActivityType.memberJoined);
      expect(entry.actorMemberId, bilalId);
    });
  });

  group('settings', () {
    late String id;
    late Member me;
    setUp(() async {
      id = await create();
      me = (await members(id)).single;
    });

    test('renaming the group logs the old and new name', () async {
      await repo.updateGroup(
        group: await groupOf(id),
        actorMemberId: me.id,
        name: 'Chai Club',
        type: 'Office',
      );
      final g = await groupOf(id);
      expect(g.name, 'Chai Club');
      expect(g.type, 'Office');
      final entry = (await activity(id))
          .firstWhere((a) => a.type == ActivityType.groupRenamed);
      expect(entry.before, {'name': 'Chai', 'type': 'Friends'});
      expect(entry.after, {'name': 'Chai Club', 'type': 'Office'});
    });

    test('a new join code replaces the old one, which stops working', () async {
      final old = (await groupOf(id)).joinCode;
      final fresh = await repo.regenerateJoinCode(
        group: await groupOf(id),
        actorMemberId: me.id,
      );
      expect(fresh, isNot(old));
      expect((await groupOf(id)).joinCode, fresh);
      expect(await repo.findGroupByCode(fresh), id);
      expect(await repo.findGroupByCode(old), isNull);
    });
  });

  group('leaving and deleting', () {
    late String id;
    late String code;
    setUp(() async {
      id = await create();
      code = (await groupOf(id)).joinCode;
    });

    Future<String> addSara() async {
      await repo.join(groupId: id, code: code, uid: 'u-sara');
      return repo.joinAsNewMember(
        groupId: id,
        uid: 'u-sara',
        displayName: 'Sara',
      );
    }

    test('leaving hides your member and removes your uid', () async {
      final saraId = await addSara();
      await repo.leave(
        groupId: id,
        member: await member(id, saraId),
        uid: 'u-sara',
      );
      expect((await groupOf(id)).memberUids, ['u-ali']);
      expect((await member(id, saraId)).active, isFalse);
      final entry = (await activity(id))
          .firstWhere((a) => a.type == ActivityType.memberLeft);
      expect(entry.actorMemberId, saraId);
    });

    test('coming back reuses the old member and its history', () async {
      final saraId = await addSara();
      await repo.leave(
        groupId: id,
        member: await member(id, saraId),
        uid: 'u-sara',
      );
      await repo.rejoin(groupId: id, member: await member(id, saraId));
      expect((await member(id, saraId)).active, isTrue);
      expect(await members(id), hasLength(2));
    });

    test('deleting removes the group, everything in it and its code', () async {
      await repo.addPlaceholder(
        groupId: id,
        actorMemberId: (await members(id)).single.id,
        name: 'Sara',
      );
      await db.collection('groups/$id/expenses').add({'title': 'Chai'});
      await db.collection('groups/$id/settlements').add({'amount': 100});
      await repo.deleteGroup(await groupOf(id));

      expect((await db.doc('groups/$id').get()).exists, isFalse);
      for (final sub in ['members', 'expenses', 'settlements', 'activity']) {
        final left = await db.collection('groups/$id/$sub').get();
        expect(left.docs, isEmpty, reason: sub);
      }
      expect(await repo.findGroupByCode(code), isNull);
    });

    test('deleting a group bigger than one Firestore batch', () async {
      for (var i = 0; i < 520; i++) {
        await db.collection('groups/$id/activity').add({'n': i});
      }
      await repo.deleteGroup(await groupOf(id));
      final left = await db.collection('groups/$id/activity').get();
      expect(left.docs, isEmpty);
    });
  });

  group('watching', () {
    test('my groups lists only groups I am in', () async {
      final mine = await create();
      await repo.createGroup(
        uid: 'u-other',
        name: 'Trip',
        type: 'Trip',
        creatorName: 'Other',
      );
      final groups = await repo.watchMyGroups('u-ali').first;
      expect(groups.map((g) => g.id), [mine]);
    });

    test('members come in join order', () async {
      final id = await create();
      final meId = (await members(id)).single.id;
      await db.doc('groups/$id/members/$meId').update({
        'joinedAt': Timestamp.fromDate(DateTime(2030, 1, 1)),
      });
      for (final (name, minute) in [('Hamza', 3), ('Sara', 1), ('Bilal', 2)]) {
        final mid = await repo.addPlaceholder(
          groupId: id,
          actorMemberId: meId,
          name: name,
        );
        await db.doc('groups/$id/members/$mid').update({
          'joinedAt': Timestamp.fromDate(DateTime(2030, 1, 1, 0, minute)),
        });
      }
      final names = [for (final m in await members(id)) m.displayName];
      expect(names, ['Ali', 'Sara', 'Bilal', 'Hamza']);
    });

    test('a deleted group reads as gone', () async {
      final id = await create();
      await repo.deleteGroup(await groupOf(id));
      expect(await repo.watchGroup(id).first, isNull);
    });
  });

  group('saving my profile', () {
    test('updates my profile and my member in every group at once', () async {
      await db.doc('users/u-ali').set({'displayName': 'Ali', 'phone': ''});
      final a = await create(name: 'Chai');
      final b = await create(name: 'Trip');
      final other = await repo.createGroup(
        uid: 'u-other',
        name: 'Office',
        type: 'Office',
        creatorName: 'Other',
      );
      await repo.saveMyProfile(
        uid: 'u-ali',
        displayName: 'Ali Khan',
        phone: '+923009998888',
        paymentMethods: const [meezan],
      );
      final user = (await db.doc('users/u-ali').get()).data()!;
      expect(user['displayName'], 'Ali Khan');
      expect(user['phone'], '+923009998888');
      for (final id in [a, b]) {
        final me = (await members(id)).single;
        expect(me.displayName, 'Ali Khan');
        expect(me.phone, '+923009998888');
        expect(me.paymentMethods.single.id, 'p1');
      }
      expect((await members(other)).single.displayName, 'Other');
    });

    test('only the fields given change', () async {
      await db.doc('users/u-ali').set({'displayName': 'Ali', 'phone': 'x'});
      final id = await create();
      await repo.saveMyProfile(uid: 'u-ali', phone: '');
      final me = (await members(id)).single;
      expect(me.displayName, 'Ali');
      expect(me.phone, '');
      expect(me.paymentMethods, hasLength(1));
    });

    test('a placeholder in my group is never changed', () async {
      await db.doc('users/u-ali').set({'displayName': 'Ali'});
      final id = await create();
      final saraId = await repo.addPlaceholder(
        groupId: id,
        actorMemberId: (await members(id)).single.id,
        name: 'Sara',
      );
      await repo.saveMyProfile(uid: 'u-ali', phone: '+923001112222');
      expect((await member(id, saraId)).phone, '');
    });
  });
}
