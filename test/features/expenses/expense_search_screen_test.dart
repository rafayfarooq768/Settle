import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/ui/expense_search_screen.dart';
import 'package:settle/features/expenses/ui/expenses_providers.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/features/settlements/ui/settlements_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';
import 'package:settle/l10n/l10n_delegates.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final day = DateTime(2026, 11, 20, 12);
  final ali = Member(id: 'm1', displayName: 'Ali', uid: 'u1', joinedAt: day);
  final sara = Member(id: 'm2', displayName: 'Sara', joinedAt: day);

  Expense expense(String id, String title, Map<String, int> shares) {
    final amount = shares.values.fold(0, (a, b) => a + b);
    return Expense(
      id: id,
      title: title,
      amount: amount,
      date: day,
      createdBy: 'u1',
      createdAt: day,
      updatedAt: day,
      splitMode: SplitMode.exact,
      payers: {'m2': amount},
      shares: shares,
    );
  }

  final chai = expense('e1', 'Chai', {'m1': 30000, 'm2': 30000});
  final fries = expense('e2', 'Fries', {'m2': 50000});

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider('g1')
              .overrideWith((ref) => Stream.value([ali, sara])),
          myMemberProvider('g1').overrideWithValue(AsyncData(ali)),
          expensesProvider('g1')
              .overrideWith((ref) => Stream.value([chai, fries])),
          settlementsProvider('g1')
              .overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExpenseSearchScreen(groupId: 'g1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('typing narrows the list', (tester) async {
    await open(tester);
    expect(find.text('Chai'), findsOneWidget);
    expect(find.text('Fries'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'fri');
    await tester.pump();
    expect(find.text('Chai'), findsNothing);
    expect(find.text('Fries'), findsOneWidget);
  });

  testWidgets('Involves me hides expenses you are not in', (tester) async {
    await open(tester);
    await tester.tap(find.text(l10n.filterInvolvesMe));
    await tester.pump();
    expect(find.text('Chai'), findsOneWidget);
    expect(find.text('Fries'), findsNothing);
  });

  testWidgets('says so when nothing matches', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'biryani');
    await tester.pump();
    expect(find.text(l10n.searchNoResults), findsOneWidget);
  });

  // Bug (owner, 2026-11-20): the Month chip was a pixel taller.
  testWidgets('both filter chips are the same height', (tester) async {
    await open(tester);
    // The visible chip (its Material), not the 48 tap area around it.
    double visible(int i) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(FilterChip).at(i),
                matching: find.byType(Material),
              )
              .first,
        )
        .height;
    final a = visible(0);
    final b = visible(1);
    expect(b, a);
  });
}
