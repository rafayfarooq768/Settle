import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/groups/domain/join_code.dart';

void main() {
  test('prefix comes from the group name', () {
    expect(JoinCode.prefixFor('Chai'), 'CHAI');
    expect(JoinCode.prefixFor('Murree trip 2026'), 'MURR');
    expect(JoinCode.prefixFor('Ap 7'), 'AP');
    expect(JoinCode.prefixFor('گھر'), 'SETL'); // no Latin letters
  });

  test('generated codes look like CHAI-7KQ2M and normalize to themselves', () {
    final random = Random(1);
    for (var i = 0; i < 500; i++) {
      final code = JoinCode.generate('Chai', random: random);
      expect(code, matches(RegExp(r'^CHAI-[2-9A-HJKMNP-Z]{5}$')));
      expect(JoinCode.normalize(code), code);
    }
  });

  test('no look-alike characters (0/O, 1/I/L)', () {
    expect(JoinCode.alphabet, isNot(contains(RegExp('[01ILO]'))));
  });

  test('normalize accepts what people type from WhatsApp', () {
    expect(JoinCode.normalize(' chai-7kq2m '), 'CHAI-7KQ2M');
    expect(JoinCode.normalize('chai7kq2m'), 'CHAI-7KQ2M');
    expect(JoinCode.normalize('CHAI 7KQ 2M'), 'CHAI-7KQ2M');
  });

  test('normalize rejects things that cannot be codes', () {
    for (final bad in ['', 'CHAI', 'CHAI-7KQ2', 'CHAI-7KQ2MM', 'CHAI-0OIL1']) {
      expect(JoinCode.normalize(bad), isNull, reason: bad);
    }
  });
}
