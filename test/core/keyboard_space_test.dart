import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/widgets/keyboard_space.dart';

/// Owner, 2026-11-24: on Create group and Join, the button hid behind the
/// opening keyboard and jumped up about 0.3 s later (filmed on the phone).
///
/// A Scaffold makes its body shorter by the keyboard's height, so [seen] is
/// how much shorter the body is than the screen: the room it leaves.
void main() {
  late double seen;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => KeyboardSpace(child: child!),
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, box) {
            seen = MediaQuery.sizeOf(context).height - box.maxHeight;
            return Column(
              children: [
                const TextField(),
                TextButton(onPressed: () {}, child: const Text('Other')),
              ],
            );
          },
        ),
      ),
    ),
  );

  tearDown(() => KeyboardSpace.lastHeight = 0);

  testWidgets('room for the keyboard as soon as a field is focused', (
    tester,
  ) async {
    KeyboardSpace.lastHeight = 300;
    await pump(tester);
    expect(seen, 0);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(seen, 300, reason: 'before the keyboard reports its height');
  });

  testWidgets('the room goes if no keyboard comes', (tester) async {
    KeyboardSpace.lastHeight = 300;
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump(KeyboardSpace.wait);
    expect(seen, 0);
  });

  testWidgets('leaving the field gives the room back at once', (tester) async {
    KeyboardSpace.lastHeight = 300;
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(seen, 0);
  });

  testWidgets('before any keyboard has been seen, nothing changes', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(seen, 0);
  });

  testWidgets('a real keyboard is used and its full height remembered', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pump();
    expect(seen, 300);
    // Closing reports in-between heights on the way down.
    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(KeyboardSpace.lastHeight, 300);
  });

  testWidgets('an opening keyboard never shrinks the room', (tester) async {
    KeyboardSpace.lastHeight = 300;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300); // 100 dp
    await tester.pump();
    expect(seen, 300);
  });

  // Owner, 2026-11-24: the button stayed up a moment after the keyboard
  // started closing.
  testWidgets('closing gives the room back at once', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pump();
    expect(seen, 300);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(); // the keyboard still reports its full height
    expect(seen, 0);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(seen, 0);
  });

  testWidgets('screens under it keep their state', (tester) async {
    KeyboardSpace.lastHeight = 300;
    await pump(tester);
    final before = tester.state(find.byType(Scaffold));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(seen, 300);
    expect(tester.state(find.byType(Scaffold)), same(before));
  });
}
