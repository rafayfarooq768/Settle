// CLAUDE.md: money logic lives in pure Dart with no Flutter or Firebase
// imports. This keeps that true as the code grows.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/core/money imports only dart: and its own files', () {
    final files = Directory('lib/core/money')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);

    final importLine = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');
    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final uri = importLine.firstMatch(line)?.group(1);
        if (uri == null) continue;
        final allowed =
            uri.startsWith('dart:') && uri != 'dart:ui' ||
            !uri.contains(':'); // relative import within lib/core/money
        expect(allowed, isTrue, reason: '${file.path} imports $uri');
      }
    }
  });

  test('no double in money code', () {
    for (final file in Directory(
      'lib/core/money',
    ).listSync(recursive: true).whereType<File>()) {
      final code = file
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        RegExp(r'\bdouble\b|\bnum\b|toDouble\(|\.round\(').hasMatch(code),
        isFalse,
        reason: '${file.path} uses double/num',
      );
    }
  });
}
