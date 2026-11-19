import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/widgets/settle_logo.dart';

Widget _host(Widget child) => MaterialApp(home: Center(child: child));

void main() {
  testWidgets('shows name and tagline at T = 64 (sign-in size)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const SettleLogo(size: 64)));
    expect(find.text('Settle'), findsOneWidget);
    expect(find.text('HISAAB BARABAR'), findsOneWidget);
  });

  testWidgets('hides the tagline below T = 48 (BRAND.md §2)', (tester) async {
    await tester.pumpWidget(_host(const SettleLogo(size: 32)));
    expect(find.text('Settle'), findsOneWidget);
    expect(find.text('HISAAB BARABAR'), findsNothing);
  });

  testWidgets('includes 0.25 T clear space on every side', (tester) async {
    await tester.pumpWidget(_host(const SettleLogo(size: 64, showName: false)));
    final size = tester.getSize(find.byType(SettleLogo));
    expect(size, const Size(64 + 2 * 16, 64 + 2 * 16));
  });

  testWidgets('is announced as "Settle" to screen readers', (tester) async {
    await tester.pumpWidget(_host(const SettleLogo(size: 64)));
    expect(find.bySemanticsLabel('Settle'), findsOneWidget);
  });
}
