import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../../activity/data/activity_log.dart';
import '../../activity/domain/activity.dart';
import '../../profile/domain/payment_method.dart';
import '../domain/group.dart';
import '../domain/join_code.dart';
import 'group_mapper.dart';
import '../../../core/firestore/retry_when_denied.dart';

/// Groups, members and join codes (PLAN.md §6, §7). The only place that
/// touches these collections. Every change also writes an activity entry in
/// the same batch.
class GroupRepository {
  GroupRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Json> get _groups => _db.collection(Col.groups);
  DocumentReference<Json> _group(String id) => _groups.doc(id);
  CollectionReference<Json> _members(String groupId) =>
      _group(groupId).collection(Col.members);
  DocumentReference<Json> _code(String code) =>
      _db.collection(Col.joinCodes).doc(code);

  Stream<List<Group>> watchMyGroups(String uid) => _groups
      .where('memberUids', arrayContains: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) groupFromMap(d.id, d.data())]);

  Stream<Group?> watchGroup(String groupId) =>
      retryWhenDenied(() => _group(groupId).snapshots())
          .map((d) => d.exists ? groupFromMap(d.id, d.data()!) : null);

  /// In join order, so leftover-paisa and settle-up order are stable.
  Stream<List<Member>> watchMembers(String groupId) =>
      retryWhenDenied(() => _members(groupId).snapshots()).map((s) {
        final members = [for (final d in s.docs) memberFromMap(d.id, d.data())];
        members.sort((a, b) {
          final byDate = a.joinedAt.compareTo(b.joinedAt);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
        return members;
      });

  /// Creates the group with the creator as its first member. Returns the
  /// group id.
  Future<String> createGroup({
    required String uid,
    required String name,
    required String type,
    required String creatorName,
    List<PaymentMethod> paymentMethods = const [],
    String phone = '',
  }) async {
    final group = _groups.doc();
    final me = _members(group.id).doc();
    final code = await _freshCode(name);

    final batch = _db.batch()
      ..set(group, {
        'name': name,
        'type': type,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'joinCode': code,
        'currency': 'PKR',
        'memberUids': [uid],
      })
      ..set(
        me,
        _newMember(
          creatorName,
          uid: uid,
          methods: paymentMethods,
          phone: phone,
        ),
      )
      ..set(_code(code), {'groupId': group.id});
    logActivity(
      batch,
      group,
      type: ActivityType.groupCreated,
      actorMemberId: me.id,
      targetId: group.id,
      summary: name,
    );
    await commitOrQueue(batch);
    return group.id;
  }

  /// A friend added by name before they install (PLAN.md §6).
  Future<String> addPlaceholder({
    required String groupId,
    required String actorMemberId,
    required String name,
  }) async {
    final member = _members(groupId).doc();
    final batch = _db.batch()..set(member, _newMember(name));
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.placeholderAdded,
      actorMemberId: actorMemberId,
      targetId: member.id,
      summary: name,
    );
    await commitOrQueue(batch);
    return member.id;
  }

  Future<void> renamePlaceholder({
    required String groupId,
    required String actorMemberId,
    required Member member,
    required String name,
  }) async {
    final batch = _db.batch()
      ..update(_members(groupId).doc(member.id), {'displayName': name});
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.memberRenamed,
      actorMemberId: actorMemberId,
      targetId: member.id,
      summary: name,
      before: {'displayName': member.displayName},
      after: {'displayName': name},
    );
    await commitOrQueue(batch);
  }

  /// Hides an unclaimed placeholder (owner's decision, PLAN.md §6). It stays
  /// in the database so past expenses keep its name. The caller checks the
  /// balance is zero first.
  Future<void> removePlaceholder({
    required String groupId,
    required String actorMemberId,
    required Member placeholder,
  }) async {
    final batch = _db.batch()
      ..update(_members(groupId).doc(placeholder.id), {'active': false});
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.placeholderRemoved,
      actorMemberId: actorMemberId,
      targetId: placeholder.id,
      summary: placeholder.displayName,
    );
    await commitOrQueue(batch);
  }

  /// The group id for what the user typed or scanned, or null if the code
  /// doesn't exist (wrong, or regenerated). Needs a connection.
  Future<String?> findGroupByCode(String input) async {
    final code = JoinCode.normalize(input);
    if (code == null) return null;
    final doc = await _code(code).get(const GetOptions(source: Source.server));
    return doc.exists ? doc.data()!['groupId'] as String? : null;
  }

  /// Adds the user to the group. Writing under `joinCodes/{code}/joins` is
  /// how the security rules know the user had the current code. After this
  /// the user can read the members and pick "Which one are you?".
  Future<void> join({
    required String groupId,
    required String code,
    required String uid,
  }) async {
    final normalized = JoinCode.normalize(code) ?? code;
    final batch = _db.batch()
      ..set(_code(normalized).collection(Col.joins).doc(uid), {
        'groupId': groupId,
        'joinedAt': FieldValue.serverTimestamp(),
      })
      ..update(_group(groupId), {
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    await batch.commit(); // must reach the server
  }

  /// "That's me": takes over a placeholder and its history.
  Future<void> claimPlaceholder({
    required String groupId,
    required Member placeholder,
    required String uid,
    List<PaymentMethod> paymentMethods = const [],
    String phone = '',
  }) async {
    final batch = _db.batch()
      ..update(_members(groupId).doc(placeholder.id), {
        'uid': uid,
        'claimedAt': FieldValue.serverTimestamp(),
        'paymentMethods': paymentMethodsToList(paymentMethods),
        'phone': phone,
      });
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.placeholderClaimed,
      actorMemberId: placeholder.id,
      targetId: placeholder.id,
      summary: placeholder.displayName,
    );
    await commitOrQueue(batch);
  }

  /// "I'm not listed": a new member. Returns the member id.
  Future<String> joinAsNewMember({
    required String groupId,
    required String uid,
    required String displayName,
    List<PaymentMethod> paymentMethods = const [],
    String phone = '',
  }) async {
    final member = _members(groupId).doc();
    final batch = _db.batch()
      ..set(
        member,
        _newMember(
          displayName,
          uid: uid,
          methods: paymentMethods,
          phone: phone,
        ),
      );
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.memberJoined,
      actorMemberId: member.id,
      targetId: member.id,
      summary: displayName,
    );
    await commitOrQueue(batch);
    return member.id;
  }

  /// Someone who left and came back reuses their old member (and history).
  Future<void> rejoin({required String groupId, required Member member}) async {
    final batch = _db.batch()
      ..update(_members(groupId).doc(member.id), {'active': true});
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.memberJoined,
      actorMemberId: member.id,
      targetId: member.id,
      summary: member.displayName,
    );
    await commitOrQueue(batch);
  }

  Future<void> updateGroup({
    required Group group,
    required String actorMemberId,
    required String name,
    required String type,
  }) async {
    final batch = _db.batch()
      ..update(_group(group.id), {'name': name, 'type': type});
    logActivity(
      batch,
      _group(group.id),
      type: ActivityType.groupRenamed,
      actorMemberId: actorMemberId,
      targetId: group.id,
      summary: name,
      before: {'name': group.name, 'type': group.type},
      after: {'name': name, 'type': type},
    );
    await commitOrQueue(batch);
  }

  /// Creator only (PLAN.md §6). The old code stops working at once.
  Future<String> regenerateJoinCode({
    required Group group,
    required String actorMemberId,
  }) async {
    final code = await _freshCode(group.name);
    final batch = _db.batch()
      ..update(_group(group.id), {'joinCode': code})
      ..set(_code(code), {'groupId': group.id})
      ..delete(_code(group.joinCode));
    logActivity(
      batch,
      _group(group.id),
      type: ActivityType.joinCodeRegenerated,
      actorMemberId: actorMemberId,
      targetId: group.id,
    );
    await commitOrQueue(batch);
    return code;
  }

  /// The caller must check the member's group balance is zero first
  /// (PLAN.md §6); rules can't compute balances.
  Future<void> leave({
    required String groupId,
    required Member member,
    required String uid,
  }) async {
    final batch = _db.batch()
      ..update(_members(groupId).doc(member.id), {'active': false});
    logActivity(
      batch,
      _group(groupId),
      type: ActivityType.memberLeft,
      actorMemberId: member.id,
      targetId: member.id,
      summary: member.displayName,
    );
    batch.update(_group(groupId), {
      'memberUids': FieldValue.arrayRemove([uid]),
    });
    await commitOrQueue(batch);
  }

  /// Deletes the group and everything in it. Only allowed (by the rules)
  /// when the caller is the group's last real member (PLAN.md §6). Needs a
  /// connection: it reads every doc to delete it, since Spark has no Cloud
  /// Functions to delete subcollections server-side.
  Future<void> deleteGroup(Group group) async {
    final ref = _group(group.id);
    const server = GetOptions(source: Source.server);
    final docs = <DocumentReference<Json>>[];
    for (final sub in [
      Col.expenses,
      Col.settlements,
      Col.activity,
      Col.members,
    ]) {
      final snap = await ref.collection(sub).get(server);
      docs.addAll(snap.docs.map((d) => d.reference));
    }
    // Firestore batches hold at most 500 writes.
    for (var i = 0; i < docs.length; i += 450) {
      final batch = _db.batch();
      for (final doc in docs.skip(i).take(450)) {
        batch.delete(doc);
      }
      await batch.commit();
    }
    final last = _db.batch()
      ..delete(_code(group.joinCode))
      ..delete(ref);
    await last.commit();
  }

  /// Saves your name, phone or payment methods on your profile AND on your
  /// member doc in every group, in one batch, so group-mates see the change
  /// (PLAN.md §5). Groups come from the cache when it has them: the batch is
  /// queued at once, even offline, instead of waiting on the server between
  /// steps (a save that waited could finish after a sign-out and fail).
  Future<void> saveMyProfile({
    required String uid,
    String? displayName,
    List<PaymentMethod>? paymentMethods,
    String? phone,
  }) async {
    final update = <String, Object?>{
      'displayName': ?displayName,
      'phone': ?phone,
      if (paymentMethods != null)
        'paymentMethods': paymentMethodsToList(paymentMethods),
    };
    if (update.isEmpty) return;
    final batch = _db.batch()
      ..update(_db.collection(Col.users).doc(uid), update);
    final groups = await _cacheFirst(
      _groups.where('memberUids', arrayContains: uid),
    );
    for (final group in groups.docs) {
      final mine = await _cacheFirst(
        _members(group.id).where('uid', isEqualTo: uid),
      );
      for (final member in mine.docs) {
        batch.update(member.reference, update);
      }
    }
    await commitOrQueue(batch);
  }

  /// The cached result when there is one (instant, works offline), else
  /// the server's.
  Future<QuerySnapshot<Json>> _cacheFirst(Query<Json> query) async {
    try {
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) return cached;
    } on FirebaseException {
      // Nothing cached yet: ask the server.
    }
    return query.get();
  }

  Json _newMember(
    String name, {
    String? uid,
    List<PaymentMethod> methods = const [],
    String phone = '',
  }) => {
    'displayName': name,
    'uid': uid,
    'claimedAt': null,
    'joinedAt': FieldValue.serverTimestamp(),
    'active': true,
    'paymentMethods': paymentMethodsToList(methods),
    'phone': phone,
  };

  /// A code nobody uses yet. A clash is ~1 in 28 million, so when offline we
  /// skip the check rather than block creating a group.
  Future<String> _freshCode(String groupName) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = JoinCode.generate(groupName);
      try {
        final existing = await _code(code)
            .get(const GetOptions(source: Source.server));
        if (!existing.exists) return code;
      } on FirebaseException {
        return code;
      }
    }
    return JoinCode.generate(groupName);
  }
}
