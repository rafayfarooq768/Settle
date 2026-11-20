import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/expenses/ui/add_expense_screen.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/features/profile/ui/profile_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final joined = DateTime(2026, 11, 1);
  final ali = Member(id: 'm1', displayName: 'Ali', uid: 'u1', joinedAt: joined);
  final sara = Member(id: 'm2', displayName: 'Sara', joinedAt: joined);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myIdentityProvider.overrideWithValue(
            const MyIdentity(uid: 'u1', name: 'Ali'),
          ),
          membersProvider('g1')
              .overrideWith((ref) => Stream.value([ali, sara])),
          myMemberProvider('g1').overrideWithValue(AsyncData(ali)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AddExpenseScreen(groupId: 'g1'),
        ),
      ),
    );
    await tester.pump();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

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
}
