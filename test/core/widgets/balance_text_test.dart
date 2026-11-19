import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/balance_text.dart';
import 'package:settle/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  // DESIGN.md §2: owe/owed is never shown by colour alone.
  testWidgets('your balance in words', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          BalanceText(net: -30000),
          BalanceText(net: 70000),
          BalanceText(net: 0),
        ],
      ),
    );
    expect(find.text('you owe Rs 300'), findsOneWidget);
    expect(find.text('you are owed Rs 700'), findsOneWidget);
    expect(find.text('settled up'), findsOneWidget);
  });

  testWidgets("a member's balance in words", (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          BalanceText(net: -30000, wording: BalanceWording.member),
          BalanceText(net: 33334, wording: BalanceWording.member),
        ],
      ),
    );
    expect(find.text('owes Rs 300'), findsOneWidget);
    expect(find.text('is owed Rs 333.34'), findsOneWidget);
  });

  testWidgets('headline', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          BalanceHeadline(net: 90000, settled: 'x'),
          BalanceHeadline(net: -120000, settled: 'x'),
          BalanceHeadline(net: 0, settled: "You're all settled up"),
        ],
      ),
    );
    expect(find.text('You are owed Rs 900'), findsOneWidget);
    expect(find.text('You owe Rs 1,200'), findsOneWidget);
    expect(find.text("You're all settled up"), findsOneWidget);
  });
}
