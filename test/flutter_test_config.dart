import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file. Loads the bundled brand font (Manrope), so
/// headings and the logo are measured as on the phone. Body text keeps the
/// test font, which is wider than Roboto: a layout that fits it fits the
/// phone too.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manrope = FontLoader('Manrope')
    ..addFont(rootBundle.load('assets/fonts/Manrope-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'));
  await manrope.load();
  await testMain();
}
