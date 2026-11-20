import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/widgets/app_snack_bar.dart';

void main() {
  Future<ScaffoldMessengerState> pump(WidgetTester tester) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    return key.currentState!;
  }

  /// Moves time on frame by frame, like a real screen.
  Future<void> wait(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('a plain message closes after 2.5 s', (tester) async {
    (await pump(tester)).showMessage('Saved');
    await tester.pump();
    await wait(tester, 2400);
    expect(find.text('Saved'), findsOneWidget);
    await wait(tester, 600);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('a message with Undo closes by itself after 4 s', (tester) async {
    (await pump(tester))
        .showMessage('Payment recorded', undoLabel: 'Undo', onUndo: () {});
    await tester.pump();
    await wait(tester, 3900);
    expect(find.text('Payment recorded'), findsOneWidget);
    await wait(tester, 600);
    await tester.pumpAndSettle();
    expect(find.text('Payment recorded'), findsNothing);
  });
}
