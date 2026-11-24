import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/features/auth/domain/auth_repository.dart';
import 'package:settle/features/groups/data/group_repository.dart';
import 'package:settle/l10n/app_localizations_en.dart';

import '../helpers/test_app.dart';

/// Settings, payment methods and change password (PLAN.md §5, §8 screen
/// 11): what is saved where, so friends see the change.
void main() {
  final l10n = AppLocalizationsEn();
  late FakeFirebaseFirestore db;
  late FakeAuth auth;
  late String groupId;

  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = FakeAuth(
      user: FakeUser(uid: 'u-ali', displayName: 'Ali', email: 'ali@x.com'),
    );
    await db.doc('users/u-ali').set({
      'displayName': 'Ali',
      'email': 'ali@x.com',
      'phone': '',
      'paymentMethods': <Object>[],
    });
    groupId = await GroupRepository(db).createGroup(
      uid: 'u-ali',
      name: 'Chai',
      type: 'Friends',
      creatorName: 'Ali',
    );
  });

  Future<Map<String, Object?>> profile(WidgetTester tester) =>
      real(tester, () async => (await db.doc('users/u-ali').get()).data()!);
  Future<Map<String, Object?>> myMember(WidgetTester tester) => real(
    tester,
    () async => (await db.collection('groups/$groupId/members').get())
        .docs
        .single
        .data(),
  );
  Finder sheetButton() => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byType(FilledButton),
  );

  testWidgets('shows name, email and no phone yet', (tester) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('ali@x.com'), findsOneWidget);
    expect(find.text(l10n.phoneNotAdded), findsOneWidget);
    expect(find.text(l10n.passwordRow), findsOneWidget);
  });

  testWidgets('a Google-only account has no password row', (tester) async {
    auth.hasPassword = false;
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    expect(find.text(l10n.passwordRow), findsNothing);
  });

  testWidgets('a new name reaches the profile, groups and sign-in', (
    tester,
  ) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    await tapAndSettle(tester, find.text(l10n.nameRow));
    await tester.enterText(
      find.widgetWithText(TextField, l10n.signUpNameLabel),
      'Ali Khan',
    );
    await tapAndSettle(tester, sheetButton());
    expect(find.text(l10n.nameUpdated), findsOneWidget);
    expect((await profile(tester))['displayName'], 'Ali Khan');
    expect((await myMember(tester))['displayName'], 'Ali Khan');
    expect(auth.calls, contains('name:Ali Khan'));
  });

  testWidgets('a phone is saved in +92 form, everywhere', (tester) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    await tapAndSettle(tester, find.text(l10n.phoneNotAdded));
    await tester.enterText(
      find.widgetWithText(TextField, l10n.phoneLabel),
      '0300 1234567',
    );
    await tapAndSettle(tester, sheetButton());
    expect(find.text(l10n.phoneUpdated), findsOneWidget);
    expect((await profile(tester))['phone'], '+923001234567');
    expect((await myMember(tester))['phone'], '+923001234567');
  });

  testWidgets('a wrong phone stays in the sheet with an error', (tester) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    await tapAndSettle(tester, find.text(l10n.phoneNotAdded));
    await tester.enterText(
      find.widgetWithText(TextField, l10n.phoneLabel),
      '123',
    );
    await tapAndSettle(tester, sheetButton());
    expect(find.text(l10n.errorInvalidPhone), findsOneWidget);
    expect((await profile(tester))['phone'], '');
  });

  testWidgets('a payment method is saved for group-mates to see', (
    tester,
  ) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    await tapAndSettle(tester, find.text(l10n.addPaymentMethod));
    await tapAndSettle(tester, find.text('Nayapay'));
    await tester.enterText(
      find.widgetWithText(TextField, l10n.accountNumberLabel),
      '03001234567',
    );
    await tapAndSettle(tester, find.text(l10n.saveButton));
    expect(find.text(l10n.paymentMethodSaved), findsOneWidget);

    final saved = (await profile(tester))['paymentMethods'] as List;
    expect(saved, hasLength(1));
    final method = saved.single as Map;
    expect(method['name'], 'Nayapay');
    expect(method['accountTitle'], 'Ali');
    expect(method['accountNumber'], '03001234567');
    expect((await myMember(tester))['paymentMethods'], saved);
    // Back on Settings, the new method is listed.
    expect(find.text('03001234567'), findsOneWidget);
  });

  testWidgets('a payment method needs a number', (tester) async {
    await pumpSettle(
      tester,
      db: db,
      auth: auth,
      location: '/settings/payment-methods/new',
    );
    await tapAndSettle(tester, find.text('Nayapay'));
    await tapAndSettle(tester, find.text(l10n.saveButton));
    expect(find.text(l10n.errorAccountNumberRequired), findsOneWidget);
    expect((await profile(tester))['paymentMethods'], isEmpty);
  });

  // Bug found by this test (2026-11-24): Undo ran after the screen had
  // closed and used its disposed `ref`, so the method stayed deleted.
  testWidgets('deleting a payment method can be undone', (tester) async {
    await real(
      tester,
      () => db.doc('users/u-ali').update({
        'paymentMethods': [
          {
            'id': 'p1',
            'name': 'Sadapay',
            'accountTitle': 'Ali',
            'accountNumber': '0311',
          },
        ],
      }),
    );
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    await tapAndSettle(tester, find.text('Sadapay'));
    await tapAndSettle(tester, find.text(l10n.deletePaymentMethodButton));
    expect(find.text(l10n.paymentMethodDeleted), findsOneWidget);
    expect((await profile(tester))['paymentMethods'], isEmpty);

    await tapAndSettle(tester, find.text(l10n.undoButton));
    final back = (await profile(tester))['paymentMethods'] as List;
    expect((back.single as Map)['name'], 'Sadapay');
  });

  group('Change password', () {
    testWidgets('a wrong current password is shown on that field', (
      tester,
    ) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/settings/password',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.currentPasswordLabel),
        'oops12',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.newPasswordLabel),
        'newpass1',
      );
      auth.failWith = AuthFailure.wrongPassword;
      await tapAndSettle(tester, find.text(l10n.saveButton));
      expect(find.text(l10n.errorCurrentPasswordWrong), findsOneWidget);
    });

    testWidgets('a short new password is caught first', (tester) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/settings/password',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.currentPasswordLabel),
        'secret1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.newPasswordLabel),
        '123',
      );
      await tapAndSettle(tester, find.text(l10n.saveButton));
      expect(find.text(l10n.errorWeakPassword), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('a good change says so', (tester) async {
      await pumpSettle(
        tester,
        db: db,
        auth: auth,
        location: '/settings/password',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.currentPasswordLabel),
        'secret1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.newPasswordLabel),
        'newpass1',
      );
      await tapAndSettle(tester, find.text(l10n.saveButton));
      expect(auth.calls, ['password']);
      expect(find.text(l10n.passwordChanged), findsOneWidget);
    });
  });

  testWidgets('signing out goes back to Sign in', (tester) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    await tapAndSettle(tester, find.text(l10n.signOutButton));
    expect(auth.calls, ['signOut']);
    expect(find.text(l10n.signInWithGoogle), findsOneWidget);
  });
}
