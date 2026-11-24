import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/widgets/keyboard_space.dart';
import 'package:settle/features/groups/data/group_repository.dart';
import 'package:settle/l10n/app_localizations_en.dart';

import '../helpers/test_app.dart';

/// Owner, 2026-11-24: with the keyboard fix, Add item's Save did nothing
/// and the sheet sat on the Group screen. Making room for the keyboard
/// rebuilt every screen under it. Walk the same path with it on.
void main() {
  final l10n = AppLocalizationsEn();
  late FakeFirebaseFirestore db;
  late FakeAuth auth;
  late String groupId;

  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = FakeAuth(
      user: FakeUser(uid: 'u-ali', displayName: 'Ali'),
    );
    final groups = GroupRepository(db);
    groupId = await groups.createGroup(
      uid: 'u-ali',
      name: 'Dinner',
      type: 'Friends',
      creatorName: 'Ali',
    );
    final ali = (await groups.watchMembers(groupId).first).single.id;
    await groups.addPlaceholder(
      groupId: groupId,
      actorMemberId: ali,
      name: 'Sara',
    );
  });

  tearDown(() => KeyboardSpace.lastHeight = 0);

  testWidgets('Add item saves while the keyboard makes room', (tester) async {
    KeyboardSpace.lastHeight = 300; // a keyboard has been seen before
    await pumpSettle(
      tester,
      db: db,
      auth: auth,
      location: '/groups/$groupId/expenses/new',
    );
    await tester.enterText(find.byType(TextField).first, '1000');
    await settle(tester);
    await tapAndSettle(tester, find.text(l10n.splitEqually(2)));
    await tapAndSettle(tester, find.textContaining(l10n.itemsOpen));
    await tapAndSettle(tester, find.text(l10n.itemsAdd));

    await tester.enterText(
      find.widgetWithText(TextField, l10n.itemNameLabel),
      'Steak',
    );
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, l10n.itemPriceLabel),
      '1500',
    );
    await settle(tester);
    await tapAndSettle(tester, find.widgetWithText(FilterChip, 'Sara'));
    await tapAndSettle(tester, find.text(l10n.itemSaveButton));

    expect(find.text(l10n.itemSaveButton), findsNothing);
    expect(find.text(l10n.itemsTitle), findsWidgets, reason: 'still there');
    expect(find.text('Steak'), findsOneWidget);
  });
}
