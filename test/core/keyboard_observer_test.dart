import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/router/keyboard_observer.dart';
import 'package:settle/core/widgets/app_sheet.dart';

void main() {
  Future<FocusNode> open(WidgetTester tester, {required bool observer}) async {
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [if (observer) KeyboardStaysClosedObserver()],
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextField(focusNode: field, autofocus: true),
                TextButton(
                  onPressed: () => showAppSheet<void>(
                    context: context,
                    builder: (sheet) => TextButton(
                      onPressed: () => Navigator.of(sheet).pop(),
                      child: const Text('close'),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(field.hasFocus, isTrue);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    return field;
  }

  // Bug (owner, 2026-11-20): closing a sheet re-focused the field below and
  // opened the keyboard.
  testWidgets('closing a sheet leaves the field below unfocused', (
    tester,
  ) async {
    final field = await open(tester, observer: true);
    expect(field.hasFocus, isFalse);
  });

  testWidgets('without the observer Flutter would refocus it', (tester) async {
    final field = await open(tester, observer: false);
    expect(field.hasFocus, isTrue);
  });
}
