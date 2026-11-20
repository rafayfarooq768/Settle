import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/profile/domain/payment_method.dart';
import 'package:settle/features/settlements/ui/payment_sheet.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';
import 'package:settle/l10n/l10n_delegates.dart';

const meezan = PaymentMethod(
  id: 'a',
  name: 'Meezan Bank',
  accountTitle: 'Ali Khan',
  accountNumber: 'PK36MEZN0001',
);
const nayapay = PaymentMethod(
  id: 'b',
  name: 'Nayapay',
  accountTitle: 'Ali Khan',
  accountNumber: '03001234567',
);

void main() {
  final l10n = AppLocalizationsEn();

  Future<void> open(WidgetTester tester, List<PaymentMethod> list) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPaymentSheet(
                context,
                title: 'Pay Ali',
                hint: 'You owe Ali Rs 300',
                action: l10n.iPaidButton,
                initial: 30000,
                methods: (
                  list: list,
                  label: l10n.payMethodsLabel('Ali'),
                  emptyText: l10n.payNoMethods('Ali'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the methods in the order they were added', (tester) async {
    await open(tester, [meezan, nayapay]);
    expect(find.text(l10n.payMethodsLabel('Ali')), findsOneWidget);
    final bank = tester.getTopLeft(find.text('PK36MEZN0001')).dy;
    final naya = tester.getTopLeft(find.text('03001234567')).dy;
    expect(bank, lessThan(naya));
  });

  testWidgets('copy puts the number on the clipboard and shows a tick', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await open(tester, [nayapay]);
    await tester.tap(find.byTooltip(l10n.copyNumberTooltip));
    await tester.pump();
    expect(copied, '03001234567');
    expect(find.byIcon(Icons.check), findsOneWidget);
    // The tick goes back to the copy icon by itself.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('with no methods, says to ask them', (tester) async {
    await open(tester, []);
    expect(find.text(l10n.payNoMethods('Ali')), findsOneWidget);
  });
}
