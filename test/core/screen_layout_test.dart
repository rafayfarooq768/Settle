import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/widgets/screen_layout.dart';

Widget _screen({required bool pinned}) => MaterialApp(
  home: Scaffold(
    body: ScreenLayout(
      pinned: pinned,
      body: [for (var i = 0; i < 30; i++) ListTile(title: Text('Person $i'))],
      actions: [FilledButton(onPressed: () {}, child: const Text('Done'))],
    ),
  ),
);

void main() {
  // Bug (2026-11-20 final check): with six people the Split screen's Done
  // sat below the screen, under the system navigation bar.
  testWidgets('pinned: Done stays on screen under a long list', (tester) async {
    await tester.pumpWidget(_screen(pinned: true));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final done = tester.getRect(find.text('Done'));
    expect(done.bottom, lessThanOrEqualTo(screen.height));
  });

  testWidgets('not pinned: Done scrolls with a long form', (tester) async {
    await tester.pumpWidget(_screen(pinned: false));
    expect(find.text('Done').hitTestable(), findsNothing);
  });
}
