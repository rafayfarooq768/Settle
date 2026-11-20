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
  testWidgets('your balance in a row: words over the amount', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          BalanceStack(net: -30000),
          BalanceStack(net: 70000),
          BalanceStack(net: 0),
        ],
      ),
    );
    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('Rs 300'), findsOneWidget);
    expect(find.text('You are owed'), findsOneWidget);
    expect(find.text('Rs 700'), findsOneWidget);
    expect(find.text('Settled up'), findsOneWidget);
  });

  testWidgets("a member's balance", (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          BalanceStack(net: -30000, wording: BalanceWording.member),
          BalanceStack(net: 33334, wording: BalanceWording.member),
        ],
      ),
    );
    expect(find.text('Owes'), findsOneWidget);
    expect(find.text('Gets back'), findsOneWidget);
    expect(find.text('Rs 333.34'), findsOneWidget);
  });

  testWidgets('the big balance: words, then a small Rs and the number', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: [
          BalanceHero(net: 90000, large: false),
          BalanceHero(net: -120000),
          BalanceHero(net: 0, settledText: "You're all settled up"),
        ],
      ),
    );
    expect(find.text('You are owed'), findsOneWidget);
    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('Rs 900', findRichText: true), findsOneWidget);
    expect(find.text('Rs 1,200', findRichText: true), findsOneWidget);
    expect(find.text("You're all settled up"), findsOneWidget);
  });
}
