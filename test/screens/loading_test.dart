import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/balance_text.dart';
import 'package:settle/features/expenses/data/expense_repository.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/expense_summary.dart';
import 'package:settle/features/expenses/ui/expenses_providers.dart';
import 'package:settle/features/groups/data/group_repository.dart';
import 'package:settle/features/profile/domain/app_user.dart';
import 'package:settle/features/profile/ui/profile_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';
import 'package:settle/l10n/l10n_delegates.dart';

import '../helpers/test_app.dart';

/// While data is still loading, a screen shows nothing wrong: no
/// "settled", no partial total, no empty list that is really just late
/// (owner, 2026-11-24: "it takes a second to go from you're settled to my
/// real owed balance").
void main() {
  final l10n = AppLocalizationsEn();
  late FakeFirebaseFirestore db;
  late FakeAuth auth;
  late String chai;
  late String trip;

  // Ali is owed Rs 600 in Chai and owes Rs 100 in Trip.
  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = FakeAuth(
      user: FakeUser(uid: 'u-ali', displayName: 'Ali'),
    );
    await db.doc('users/u-ali').set({
      'displayName': 'Ali',
      'phone': '+923001234567',
      'paymentMethods': [
        {
          'id': 'p1',
          'name': 'Nayapay',
          'accountTitle': 'Ali',
          'accountNumber': '0300',
        },
      ],
    });
    final groups = GroupRepository(db);
    Future<String> group(String name, int paid, int share) async {
      final id = await groups.createGroup(
        uid: 'u-ali',
        name: name,
        type: 'Friends',
        creatorName: 'Ali',
      );
      final ali = (await groups.watchMembers(id).first).single.id;
      final sara = await groups.addPlaceholder(
        groupId: id,
        actorMemberId: ali,
        name: 'Sara',
      );
      await ExpenseRepository(db).add(
        groupId: id,
        uid: 'u-ali',
        actorMemberId: ali,
        draft: ExpenseDraft(
          title: name,
          amount: 100000,
          date: DateTime.now(),
          splitMode: SplitMode.exact,
          payers: {ali: paid, sara: 100000 - paid},
          shares: {ali: share, sara: 100000 - share},
        ),
      );
      return id;
    }

    chai = await group('Chai', 100000, 40000); // Ali +600
    trip = await group('Trip', 0, 10000); // Ali −100
  });

  testWidgets('BalanceHero while loading: no words, same height', (
    tester,
  ) async {
    Future<Size> sizeOf(int? net) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: BalanceHero(net: net),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(BalanceHero).first);
    }

    final loaded = await sizeOf(60000);
    final loading = await sizeOf(null);
    // The placeholder keeps its size with invisible text, so look only
    // at what a person can see or a screen reader can read.
    for (final words in [
      l10n.heroAllSettled,
      l10n.heroYourBalance,
      l10n.heroYouAreOwed,
    ]) {
      expect(find.text(words).hitTestable(), findsNothing);
      expect(find.bySemanticsLabel(words), findsNothing);
    }
    expect(loading, loaded, reason: 'nothing moves when it arrives');
  });

  testWidgets('Home never shows "settled" or a part of the total', (
    tester,
  ) async {
    // Trip's expenses are still on their way.
    await pumpSettle(
      tester,
      db: db,
      auth: auth,
      overrides: [expensesProvider(trip).overrideWith((ref) => neverLoads())],
    );
    expect(find.text(l10n.balanceAllSettled), findsNothing);
    expect(
      find.textContaining('600', findRichText: true),
      findsNothing,
      reason: 'Chai alone is not it',
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Home, once everything is here, shows the whole total', (
    tester,
  ) async {
    await pumpSettle(tester, db: db, auth: auth);
    // In Overall and on the Chai row.
    expect(find.text(l10n.heroYouAreOwed), findsNWidgets(2));
    expect(
      find.textContaining('500', findRichText: true),
      findsOneWidget,
    ); // 600 − 100
    expect(find.text(l10n.balanceBothLine('Rs 100', 'Rs 600')), findsOneWidget);
  });

  testWidgets('the group header waits instead of saying "All settled"', (
    tester,
  ) async {
    await pumpSettle(
      tester,
      db: db,
      auth: auth,
      location: '/groups/$chai',
      overrides: [expensesProvider(chai).overrideWith((ref) => neverLoads())],
    );
    expect(find.text(l10n.heroAllSettled).hitTestable(), findsNothing);
    expect(find.text(l10n.heroYourBalance).hitTestable(), findsNothing);
    expect(find.text(l10n.heroYouAreOwed).hitTestable(), findsNothing);
    expect(find.byType(BalanceHero), findsWidgets);
  });

  testWidgets('Settings waits for the profile: no false "Not added"', (
    tester,
  ) async {
    await pumpSettle(
      tester,
      db: db,
      auth: auth,
      location: '/settings',
      overrides: [
        myProfileProvider.overrideWith((ref) => neverLoads<AppUser?>()),
      ],
    );
    expect(find.text(l10n.phoneNotAdded), findsNothing);
    expect(find.text(l10n.addPaymentMethod), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Settings, once loaded, shows the phone and methods', (
    tester,
  ) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/settings');
    expect(find.text(l10n.phoneNotAdded), findsNothing);
    expect(find.text('Nayapay'), findsOneWidget);
  });

  test('preloading a group puts its names on the phone', () async {
    await GroupRepository(db).preloadGroup(chai);
    final names = await db.collection('groups/$chai/members').get();
    expect(names.docs.map((d) => d.data()['displayName']), ['Ali', 'Sara']);
  });

  // Owner, 2026-11-24: the label and hint of a field that gets the cursor
  // when its screen opens appeared about a second late.
  testWidgets('Create group: the name label is at the top at once', (
    tester,
  ) async {
    await pumpSettle(tester, db: db, auth: auth, location: '/groups/new');
    final name = tester.widget<TextField>(
      find.widgetWithText(TextField, l10n.groupNameLabel),
    );
    expect(
      name.decoration!.floatingLabelBehavior,
      FloatingLabelBehavior.always,
    );
  });
}
