import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/member_avatar.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/ui/expense_list.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';
import 'package:settle/l10n/l10n_delegates.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final day = DateTime(2026, 11, 20, 12);

  Expense dinner({bool pendingSync = false}) => Expense(
    id: 'e1',
    title: 'Dinner Shawarma at the place near the university',
    amount: 1119734,
    date: day,
    createdBy: 'u1',
    createdAt: day,
    updatedAt: day,
    splitMode: SplitMode.exact,
    payers: {'me': 1119734},
    shares: {'me': 188136, 'h': 931598},
    pendingSync: pendingSync,
  );

  Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(body: child),
          ),
        ),
      );

  // Critique 2026-11-20 (P1): at font size 1.3 the row read
  // "You paid Rs 11,…". An amount must never be cut off.
  testWidgets('the paid line is never cut off at a large font size', (
    tester,
  ) async {
    await pump(
      tester,
      ExpenseRow(expense: dinner(), names: const {}, meId: 'me', onTap: () {}),
      scale: 2,
    );
    final line = tester.widget<Text>(
      find.text(l10n.expenseYouPaid('Rs 11,197.34')),
    );
    expect(line.overflow, isNot(TextOverflow.ellipsis));
    expect(line.maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an expense saved offline says it is not synced yet', (
    tester,
  ) async {
    await pump(
      tester,
      ExpenseRow(
        expense: dinner(pendingSync: true),
        names: const {},
        meId: 'me',
      ),
    );
    expect(find.text(l10n.notSyncedYet), findsOneWidget);

    await pump(
      tester,
      ExpenseRow(expense: dinner(), names: const {}, meId: 'me'),
    );
    expect(find.text(l10n.notSyncedYet), findsNothing);
  });

  // Audit 2026-11-20: "RF" spilled out of the 28dp avatars at font 1.3.
  testWidgets('avatar initials keep their size at a large font size', (
    tester,
  ) async {
    await pump(
      tester,
      const Center(child: MemberAvatar(name: 'Rafay Farooq', size: 28)),
      scale: 2,
    );
    final initials = tester.getSize(find.text('RF'));
    expect(initials.width, lessThan(28));
    expect(initials.height, lessThan(28));
  });
}
