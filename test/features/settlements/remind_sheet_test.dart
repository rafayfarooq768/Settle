import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/config/app_links.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/settlements/ui/remind_sheet.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Future<void> open(WidgetTester tester, {String phone = ''}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showRemindSheet(
                context,
                title: 'Remind Sara',
                message: 'Salam!',
                phone: phone,
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

  testWidgets('says which chat it opens', (tester) async {
    await open(tester, phone: '+923001234567');
    expect(find.text(l10n.remindSendsTo('+92 300 1234567')), findsOneWidget);
  });

  testWidgets('without a number, WhatsApp asks who', (tester) async {
    await open(tester);
    expect(find.text(l10n.remindPickChat), findsOneWidget);
  });

  test('wa.me links go to the number, with the text', () {
    expect(
      AppLinks.whatsAppTo('923001234567', 'Salam yaar').toString(),
      'https://wa.me/923001234567?text=Salam+yaar',
    );
  });
}
