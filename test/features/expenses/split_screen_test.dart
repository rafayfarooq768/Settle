import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/loading_button.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/domain/split_spec.dart';
import 'package:settle/features/expenses/ui/split_screen.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final joined = DateTime(2026, 11, 1);
  final ali = Member(id: 'm1', displayName: 'Ali', uid: 'u1', joinedAt: joined);
  final sara = Member(id: 'm2', displayName: 'Sara', joinedAt: joined);

  Future<void> open(WidgetTester tester, {SplitSpec? spec}) async {
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
          home: SplitScreen(
            groupId: 'g1',
            args: SplitArgs(
              amount: 100000,
              payerIds: const ['m1'],
              meId: 'm1',
              spec: spec ?? const EqualSpec(['m1', 'm2']),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool doneEnabled(WidgetTester tester) =>
      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed !=
      null;

  Finder inputs() => find.descendant(
    of: find.byType(ListTile),
    matching: find.byType(TextField),
  );

  testWidgets('equal shows each part and allows Done', (tester) async {
    await open(tester);
    expect(find.text(l10n.splitTitleAmount('Rs 1,000')), findsOneWidget);
    expect(find.text('Rs 500'), findsNWidgets(2));
    expect(doneEnabled(tester), isTrue);
  });

  testWidgets('exact: live left line, Done only when it adds up', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(l10n.splitModeExact));
    await tester.pump();
    expect(find.text(l10n.splitLeftToAssign('Rs 1,000')), findsOneWidget);
    expect(doneEnabled(tester), isFalse);

    await tester.enterText(inputs().at(0), '300');
    await tester.pump();
    expect(find.text(l10n.splitLeftToAssign('Rs 700')), findsOneWidget);

    await tester.enterText(inputs().at(1), '800');
    await tester.pump();
    expect(find.text(l10n.splitTooMuch('Rs 100')), findsOneWidget);
    expect(doneEnabled(tester), isFalse);

    await tester.enterText(inputs().at(1), '700');
    await tester.pump();
    expect(find.text(l10n.splitAddsUp('Rs 1,000')), findsOneWidget);
    expect(doneEnabled(tester), isTrue);
  });

  testWidgets('percent: must reach 100%, shows the rupees', (tester) async {
    await open(tester);
    await tester.tap(find.text(l10n.splitModePercent));
    await tester.pump();
    await tester.enterText(inputs().at(0), '60');
    await tester.pump();
    expect(find.text(l10n.splitLeftToAssign('40%')), findsOneWidget);
    expect(doneEnabled(tester), isFalse);
    await tester.enterText(inputs().at(1), '40');
    await tester.pump();
    expect(find.text('Rs 600'), findsOneWidget);
    expect(find.text('Rs 400'), findsOneWidget);
    expect(doneEnabled(tester), isTrue);
  });

  testWidgets('shares start at 1 each and can be changed', (tester) async {
    await open(tester);
    await tester.tap(find.text(l10n.splitModeShares));
    await tester.pump();
    expect(find.text(l10n.splitSharesCount(2)), findsOneWidget);
    await tester.enterText(inputs().at(0), '3');
    await tester.pump();
    expect(find.text('Rs 750'), findsOneWidget);
    expect(find.text('Rs 250'), findsOneWidget);
  });

  testWidgets('reopening keeps what was entered', (tester) async {
    await open(tester, spec: const ExactSpec({'m1': 25050, 'm2': 74950}));
    final seg = tester.widget<SegmentedButton<SplitMode>>(
      find.byType(SegmentedButton<SplitMode>),
    );
    expect(seg.selected, {SplitMode.exact});
    expect(find.text('250.50'), findsOneWidget);
    expect(doneEnabled(tester), isTrue);
  });
}
