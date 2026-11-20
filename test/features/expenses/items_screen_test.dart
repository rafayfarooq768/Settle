import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/loading_button.dart';
import 'package:settle/features/expenses/domain/split_spec.dart';
import 'package:settle/features/expenses/ui/items_screen.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final joined = DateTime(2026, 11, 1);
  final ali = Member(id: 'm1', displayName: 'Ali', uid: 'u1', joinedAt: joined);
  final sara = Member(id: 'm2', displayName: 'Sara', joinedAt: joined);

  Future<void> open(WidgetTester tester, {ItemizedSpec? spec}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider('g1')
              .overrideWith((ref) => Stream.value([ali, sara])),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ItemsScreen(
            groupId: 'g1',
            args: ItemsArgs(
              amount: null,
              meId: 'm1',
              payerIds: const ['m1'],
              spec: spec,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool done(WidgetTester tester) =>
      tester.widget<LoadingButton>(find.byType(LoadingButton).last).onPressed !=
      null;

  testWidgets('Done stays off until there is an item', (tester) async {
    await open(tester);
    expect(find.text(l10n.billTotal('Rs 0')), findsOneWidget);
    expect(done(tester), isFalse);
  });

  testWidgets('add an item for one person, then tax', (tester) async {
    await open(tester);
    await tester.tap(find.text(l10n.itemsAdd));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.itemNameLabel),
      'Steak',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.itemPriceLabel),
      '1500',
    );
    // Nobody is ticked to start with: saving asks who had it.
    await tester.tap(find.text(l10n.itemSaveButton));
    await tester.pump();
    expect(find.text(l10n.errorPickWhoHad), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Ali (you)'));
    await tester.pump();
    await tester.tap(find.text(l10n.itemSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('Steak'), findsOneWidget);
    expect(find.text(l10n.billTotal('Rs 1,500')), findsOneWidget);
    expect(done(tester), isTrue);

    final tax = find.descendant(
      of: find.widgetWithText(ListTile, l10n.taxLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(tax, '10');
    await tester.pump();
    expect(find.text(l10n.billTotal('Rs 1,650')), findsOneWidget);
    // The tax shows what it comes to; only Ali had anything, so only
    // Ali owes, tax included.
    expect(find.text('Rs 150'), findsOneWidget);
    expect(find.text(l10n.whoOwesSection), findsOneWidget);
    expect(find.text('Rs 1,650'), findsOneWidget);
    expect(find.text('Sara'), findsNothing);
  });

  testWidgets('tax can switch to Rs and keeps what it comes to', (
    tester,
  ) async {
    await open(
      tester,
      spec: const ItemizedSpec(
        items: [
          BillLine(name: 'Steak', amount: 300000, memberIds: ['m1']),
        ],
        taxBp: 1600,
      ),
    );
    expect(find.text(l10n.billTotal('Rs 3,480')), findsOneWidget);
    // The % is a button: tap it to switch to Rs.
    await tester.tap(find.text(l10n.percentSuffix).first);
    await tester.pump();
    expect(find.text('480'), findsOneWidget);
    expect(find.text(l10n.billTotal('Rs 3,480')), findsOneWidget);
  });

  testWidgets('the switch says what it does now', (tester) async {
    await open(tester);
    expect(find.text(l10n.extrasByOrder), findsOneWidget);
    await tester.tap(find.text(l10n.extrasEqually));
    await tester.pump();
    expect(find.text(l10n.extrasSameForAll), findsOneWidget);
  });

  testWidgets('an item can be deleted', (tester) async {
    await open(
      tester,
      spec: const ItemizedSpec(
        items: [
          BillLine(name: 'Chai', amount: 20000, memberIds: ['m1', 'm2']),
        ],
      ),
    );
    expect(find.text(l10n.itemEveryone), findsOneWidget);
    await tester.tap(find.text('Chai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.itemDeleteButton));
    await tester.pumpAndSettle();
    expect(find.text('Chai'), findsNothing);
    expect(done(tester), isFalse);
  });
}
