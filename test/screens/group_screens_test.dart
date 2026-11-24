import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/features/expenses/data/expense_repository.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';
import 'package:settle/features/groups/data/group_repository.dart';
import 'package:settle/l10n/app_localizations_en.dart';

import '../helpers/test_app.dart';

/// Group screens on the real router and an in-memory Firestore: what a
/// person sees and what gets saved when they tap.
void main() {
  final l10n = AppLocalizationsEn();
  late FakeFirebaseFirestore db;
  late FakeAuth auth;
  late GroupRepository groups;
  late String groupId;
  late Map<String, String> ids; // name → memberId

  // Ali (signed in) paid Rs 900 for chai, split equally with two friends
  // who haven't joined yet: Sara and Bilal each owe Ali Rs 300.
  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = FakeAuth(
      user: FakeUser(uid: 'u-ali', displayName: 'Ali', email: 'ali@x.com'),
    );
    groups = GroupRepository(db);
    await db.doc('users/u-ali').set({
      'displayName': 'Ali',
      'email': 'ali@x.com',
      'phone': '',
      'paymentMethods': <Object>[],
    });
    groupId = await groups.createGroup(
      uid: 'u-ali',
      name: 'Chai',
      type: 'Friends',
      creatorName: 'Ali',
    );
    final ali = (await groups.watchMembers(groupId).first).single.id;
    ids = {'Ali': ali};
    for (final name in ['Sara', 'Bilal']) {
      ids[name] = await groups.addPlaceholder(
        groupId: groupId,
        actorMemberId: ali,
        name: name,
      );
    }
    await ExpenseRepository(db).add(
      groupId: groupId,
      uid: 'u-ali',
      actorMemberId: ali,
      draft: ExpenseDraft(
        title: 'Chai',
        amount: 90000,
        date: DateTime.now(),
        splitMode: SplitMode.equal,
        payers: {ali: 90000},
        shares: splitEqual(amount: 90000, participants: ids.values.toList()),
      ),
    );
  });

  Future<String> joinAs(String uid, String name) async {
    final code = (await db.doc('groups/$groupId').get()).data()!['joinCode'];
    await groups.join(groupId: groupId, code: code as String, uid: uid);
    return groups.joinAsNewMember(
      groupId: groupId,
      uid: uid,
      displayName: name,
    );
  }

  group('Home', () {
    testWidgets('shows the group and what I am owed', (tester) async {
      await pumpSettle(tester, db: db, auth: auth);
      expect(find.text('Chai'), findsOneWidget);
      expect(find.text(l10n.stackYouAreOwed), findsWidgets);
      expect(find.text('Rs 600'), findsWidgets);
    });

    testWidgets('creating a group opens it', (tester) async {
      await pumpSettle(tester, db: db, auth: auth, location: '/groups/new');
      await tester.enterText(
        find.widgetWithText(TextField, l10n.groupNameLabel),
        'Murree trip',
      );
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, l10n.createGroupButton),
      );
      expect(find.text('Murree trip'), findsWidgets);
      expect(find.text(l10n.groupCreated), findsOneWidget);
      final mine = await real(
        tester,
        () => groups.watchMyGroups('u-ali').first,
      );
      expect(mine.map((g) => g.name), containsAll(['Chai', 'Murree trip']));
    });

    testWidgets('a group needs a name', (tester) async {
      await pumpSettle(tester, db: db, auth: auth, location: '/groups/new');
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, l10n.createGroupButton),
      );
      expect(find.text(l10n.errorGroupNameRequired), findsOneWidget);
      expect(
        await real(tester, () => groups.watchMyGroups('u-ali').first),
        hasLength(1),
      );
    });
  });

  group('Group', () {
    testWidgets('header, expenses, balances and settle up agree', (
      tester,
    ) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/groups/$groupId',
      );
      expect(find.text(l10n.heroYouAreOwed), findsOneWidget);
      expect(find.text(l10n.membersAndSettings(3)), findsOneWidget);
      expect(find.text(l10n.expenseYouPaid('Rs 900')), findsOneWidget);

      await tapAndSettle(tester, find.text(l10n.tabBalances));
      expect(find.text('Sara'), findsWidgets);
      expect(find.text('Rs 300'), findsWidgets);

      await tapAndSettle(tester, find.text(l10n.tabSettleUp));
      expect(find.text(l10n.transferPaysYou('Sara')), findsOneWidget);
      expect(find.text(l10n.transferPaysYou('Bilal')), findsOneWidget);
      expect(find.text(l10n.recordPaymentButton), findsNWidgets(2));
    });

    testWidgets('recording a payment settles that person', (tester) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/groups/$groupId',
      );
      await tapAndSettle(tester, find.text(l10n.tabSettleUp));
      await tapAndSettle(tester, find.text(l10n.recordPaymentButton));
      // The sheet starts at what is owed.
      expect(find.text('300'), findsOneWidget);
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(FilledButton),
        ),
      );
      expect(find.text(l10n.paymentRecorded), findsOneWidget);
      final saved = await db.collection('groups/$groupId/settlements').get();
      final payment = saved.docs.single.data();
      expect(payment['amount'], 30000);
      expect(payment['status'], 'confirmed');
      expect(payment['to'], ids['Ali']);
      expect(find.text(l10n.recordPaymentButton), findsOneWidget);
    });

    testWidgets('deleting an expense can be undone', (tester) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/groups/$groupId',
      );
      await tapAndSettle(tester, find.text(l10n.expenseYouPaid('Rs 900')));
      expect(find.text(l10n.detailYouLent('Rs 600')), findsOneWidget);
      expect(find.text(l10n.detailSplitEqual), findsOneWidget);

      await tapAndSettle(tester, find.text(l10n.deleteExpenseButton));
      expect(find.text(l10n.expenseDeleted), findsOneWidget);
      Future<bool> deleted() async =>
          (await db.collection('groups/$groupId/expenses').get()).docs.single
                  .data()['deleted']
              as bool;
      expect(await deleted(), isTrue);
      expect(find.text(l10n.heroYourBalance), findsOneWidget);

      await tapAndSettle(tester, find.text(l10n.undoButton));
      expect(await deleted(), isFalse);
      expect(find.text(l10n.heroYouAreOwed), findsOneWidget);
    });

    testWidgets('activity says who did what', (tester) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/groups/$groupId/activity',
      );
      expect(
        find.text(l10n.activityExpenseAdded(l10n.youLabel, 'Chai')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.activityPlaceholderAdded(l10n.youLabel, 'Sara')),
        findsOneWidget,
      );
    });

    testWidgets('invite shows the join code', (tester) async {
      final code = (await db.doc('groups/$groupId').get()).data()!['joinCode'];
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/groups/$groupId/invite',
      );
      expect(find.text(code as String), findsOneWidget);
      expect(find.text(l10n.shareOnWhatsApp), findsOneWidget);
    });
  });

  group('Group settings', () {
    Future<void> open(WidgetTester tester) => pumpSettle(
      tester,
      db: db,
      auth: auth,
      location: '/groups/$groupId/settings',
    ).then((_) {});

    testWidgets('a placeholder who owes cannot be removed', (tester) async {
      await open(tester);
      await tapAndSettle(tester, find.text('Sara'));
      await tapAndSettle(tester, find.text(l10n.placeholderRemove));
      expect(
        find.text(l10n.placeholderNotSettled('Sara', '− Rs 300')),
        findsOneWidget,
      );
      final sara = await db.doc('groups/$groupId/members/${ids['Sara']}').get();
      expect(sara.data()!['active'], isTrue);
    });

    testWidgets('a placeholder at zero is removed, not deleted', (
      tester,
    ) async {
      final hamza = await real(
        tester,
        () => groups.addPlaceholder(
          groupId: groupId,
          actorMemberId: ids['Ali']!,
          name: 'Hamza',
        ),
      );
      await open(tester);
      await tapAndSettle(tester, find.text('Hamza'));
      await tapAndSettle(tester, find.text(l10n.placeholderRemove));
      expect(find.text(l10n.placeholderRemoved('Hamza')), findsOneWidget);
      final doc = await db.doc('groups/$groupId/members/$hamza').get();
      expect(doc.data()!['active'], isFalse);
    });

    testWidgets('a placeholder is added by name', (tester) async {
      await open(tester);
      await tapAndSettle(tester, find.text(l10n.addPlaceholderTitle));
      await tester.enterText(
        find.widgetWithText(TextField, l10n.memberNameLabel),
        'Fatima',
      );
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(FilledButton),
        ),
      );
      final members = await real(
        tester,
        () => groups.watchMembers(groupId).first,
      );
      expect(members.map((m) => m.displayName), contains('Fatima'));
      expect(members.firstWhere((m) => m.displayName == 'Fatima').uid, isNull);
    });

    testWidgets('you cannot leave while you are owed money', (tester) async {
      await real(tester, () => joinAs('u-hamza', 'Hamza'));
      await open(tester);
      await tapAndSettle(tester, find.text(l10n.leaveGroupButton));
      expect(find.text(l10n.leaveGroupNotSettled('+ Rs 600')), findsOneWidget);
      final uids = (await db.doc('groups/$groupId').get())
          .data()!['memberUids'];
      expect(uids, contains('u-ali'));
    });

    testWidgets('the only real member deletes the group after a dialog', (
      tester,
    ) async {
      await open(tester);
      expect(find.text(l10n.leaveGroupButton), findsNothing);
      await tapAndSettle(tester, find.text(l10n.deleteGroupButton));
      expect(find.text(l10n.deleteGroupDialogTitle('Chai')), findsOneWidget);
      await tapAndSettle(
        tester,
        find.widgetWithText(TextButton, l10n.deleteGroupConfirm),
      );
      expect((await db.doc('groups/$groupId').get()).exists, isFalse);
      expect(find.text(l10n.homeNoGroupsTitle), findsOneWidget);
    });

    testWidgets('renaming the group', (tester) async {
      await open(tester);
      await tapAndSettle(tester, find.text('Chai').first);
      await tester.enterText(
        find.widgetWithText(TextField, l10n.groupNameLabel),
        'Chai Club',
      );
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(FilledButton),
        ),
      );
      final g = (await db.doc('groups/$groupId').get()).data()!;
      expect(g['name'], 'Chai Club');
    });
  });

  group('Joining', () {
    testWidgets('a friend joins with the code and claims their name', (
      tester,
    ) async {
      final code =
          (await db.doc('groups/$groupId').get()).data()!['joinCode'] as String;
      final sara = FakeAuth(
        user: FakeUser(uid: 'u-sara', displayName: 'Sara K', email: 's@x.com'),
      );
      await pumpSettle(tester, db: db, auth: sara, location: '/join');
      await tester.enterText(find.byType(TextField), code.toLowerCase());
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, l10n.joinButton),
      );
      expect(find.text(l10n.claimTitle), findsOneWidget);
      expect(find.text('Bilal'), findsOneWidget);
      expect(find.text(l10n.claimNotListed), findsOneWidget);

      await tapAndSettle(tester, find.text('Sara'));
      final member =
          (await db.doc('groups/$groupId/members/${ids['Sara']}').get())
              .data()!;
      expect(member['uid'], 'u-sara');
      final uids = (await db.doc('groups/$groupId').get())
          .data()!['memberUids'];
      expect(uids, ['u-ali', 'u-sara']);
      // Sara now sees what she owes from the chai Ali added for her.
      // At the top and on the chai row.
      expect(find.text(l10n.heroYouOwe), findsNWidgets(2));
      expect(find.text('Rs 300'), findsWidgets);
    });

    testWidgets('"I\'m not listed" joins as a new member', (tester) async {
      final code =
          (await db.doc('groups/$groupId').get()).data()!['joinCode'] as String;
      final hamza = FakeAuth(
        user: FakeUser(uid: 'u-hamza', displayName: 'Hamza', email: 'h@x.com'),
      );
      await pumpSettle(tester, db: db, auth: hamza, location: '/join');
      await tester.enterText(find.byType(TextField), code);
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, l10n.joinButton),
      );
      await tapAndSettle(tester, find.text(l10n.claimNotListed));
      final members = await real(
        tester,
        () => groups.watchMembers(groupId).first,
      );
      expect(members, hasLength(4));
      expect(members.last.uid, 'u-hamza');
      expect(members.last.displayName, 'Hamza');
    });

    testWidgets('an unknown code says so', (tester) async {
      await pumpSettle(tester, db: db, auth: auth, location: '/join');
      await tester.enterText(find.byType(TextField), 'CHAI-ZZZZZ');
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, l10n.joinButton),
      );
      expect(find.text(l10n.errorCodeNotFound), findsOneWidget);
    });
  });
}
