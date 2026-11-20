import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/amount_field.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/ui/add_expense_screen.dart';
import 'package:settle/features/expenses/ui/expenses_providers.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/features/profile/ui/profile_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/l10n_delegates.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final joined = DateTime(2026, 11, 1);
  final ali = Member(id: 'm1', displayName: 'Ali', uid: 'u1', joinedAt: joined);
  final sara = Member(id: 'm2', displayName: 'Sara', joinedAt: joined);

  Future<void> open(
    WidgetTester tester, {
    List<Expense> existing = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myIdentityProvider.overrideWithValue(
            const MyIdentity(uid: 'u1', name: 'Ali'),
          ),
          membersProvider('g1')
              .overrideWith((ref) => Stream.value([ali, sara])),
          myMemberProvider('g1').overrideWithValue(AsyncData(ali)),
          expensesProvider('g1').overrideWith((ref) => Stream.value(existing)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AddExpenseScreen(groupId: 'g1'),
        ),
      ),
    );
    await tester.pump();
  }

  Finder field(String label) => label == l10n.amountLabel
      ? find.descendant(
          of: find.byType(AmountField),
          matching: find.byType(TextField),
        )
      : find.widgetWithText(TextField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(l10n.saveButton));
    await tester.pump();
  }

  testWidgets('defaults: paid by you, split equally between everyone', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(l10n.youLabel), findsOneWidget);
    expect(find.text(l10n.splitEqually(2)), findsOneWidget);
    await tester.enterText(field(l10n.amountLabel), '1000');
    await tester.pump();
    expect(find.text(l10n.splitEach('Rs 500')), findsOneWidget);
  });

  testWidgets('Save with nothing filled shows both inline errors', (
    tester,
  ) async {
    await open(tester);
    await save(tester);
    expect(find.text(l10n.errorAmountRequired), findsOneWidget);
    expect(find.text(l10n.errorExpenseTitleRequired), findsOneWidget);
  });

  testWidgets('zero, bad and too-large amounts are refused', (tester) async {
    await open(tester);
    await tester.enterText(field(l10n.amountLabel), '0');
    await save(tester);
    expect(find.text(l10n.errorAmountRequired), findsOneWidget);

    await tester.enterText(field(l10n.amountLabel), '12.345');
    await save(tester);
    expect(find.text(l10n.errorAmountRequired), findsOneWidget);

    await tester.enterText(field(l10n.amountLabel), '2000000000');
    await save(tester);
    expect(find.text(l10n.errorAmountTooLarge), findsOneWidget);

    await tester.enterText(field(l10n.amountLabel), '1,200');
    await save(tester);
    expect(find.text(l10n.errorAmountRequired), findsNothing);
    expect(find.text(l10n.errorAmountTooLarge), findsNothing);
    expect(find.text(l10n.errorExpenseTitleRequired), findsOneWidget);
  });

  // PLAN.md §3 item 7: same amount and people a few minutes ago.
  testWidgets('the duplicate guard asks before adding the same bill twice', (
    tester,
  ) async {
    final now = DateTime.now();
    final chai = Expense(
      id: 'e1',
      title: 'Chai',
      amount: 100000,
      date: now,
      createdBy: 'u2',
      createdAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      splitMode: SplitMode.equal,
      payers: const {'m2': 100000},
      shares: const {'m1': 50000, 'm2': 50000},
    );
    await open(tester, existing: [chai]);
    await tester.pump();
    await tester.enterText(field(l10n.amountLabel), '1000');
    await tester.enterText(field(l10n.expenseTitleLabel), 'Tea');
    await save(tester);
    await tester.pumpAndSettle();
    expect(find.text(l10n.duplicateTitle), findsOneWidget);
    expect(
      find.text(l10n.duplicateBody(2, 'Chai', 'Rs 1,000')),
      findsOneWidget,
    );
    // Cancel closes it and adds nothing.
    await tester.tap(find.text(l10n.cancelButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.duplicateTitle), findsNothing);
    expect(find.text(l10n.addExpenseTitle), findsOneWidget);
  });
}
