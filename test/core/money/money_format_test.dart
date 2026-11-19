import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';

void main() {
  group('formatRupees', () {
    test('whole rupees hide paisa; thousands are grouped', () {
      expect(formatRupees(0), 'Rs 0');
      expect(formatRupees(30000), 'Rs 300');
      expect(formatRupees(120000), 'Rs 1,200');
      expect(formatRupees(123456700), 'Rs 1,234,567');
    });

    test('paisa shown only when non-zero, always 2 digits', () {
      expect(formatRupees(33334), 'Rs 333.34');
      expect(formatRupees(105), 'Rs 1.05');
      expect(formatRupees(150), 'Rs 1.50');
    });

    test('uses the absolute value', () {
      expect(formatRupees(-30000), 'Rs 300');
    });

    test('signed form always writes the sign (DESIGN.md §2)', () {
      expect(formatSignedRupees(70000), '+ Rs 700');
      expect(formatSignedRupees(-30000), '− Rs 300');
      expect(formatSignedRupees(0), 'Rs 0');
    });
  });

  group('parseRupees', () {
    test('accepts common inputs', () {
      expect(parseRupees('1200'), 120000);
      expect(parseRupees('1,200'), 120000);
      expect(parseRupees(' Rs 1,200 '), 120000);
      expect(parseRupees('Rs. 99.99'), 9999);
      expect(parseRupees('1200.5'), 120050);
      expect(parseRupees('0.1'), 10);
      expect(parseRupees('12.'), 1200);
    });

    test('rejects empty, negative, letters and over 2 decimals', () {
      for (final bad in ['', ' ', '-5', 'abc', '1.234', '1.2.3', '.5']) {
        expect(parseRupees(bad), isNull, reason: '"$bad"');
      }
    });

    test('no floating-point drift', () {
      // double would make 0.1 + 0.2 = 0.30000000000000004.
      expect(parseRupees('0.1')! + parseRupees('0.2')!, parseRupees('0.3'));
    });
  });

  group('parsePercent', () {
    test('accepts up to 2 decimals and a % sign', () {
      expect(parsePercent('33.33'), 3333);
      expect(parsePercent('10%'), 1000);
      expect(parsePercent('100'), 10000);
    });

    test('rejects over 100, negatives and junk', () {
      for (final bad in ['100.01', '-1', 'x', '1.234', '']) {
        expect(parsePercent(bad), isNull, reason: '"$bad"');
      }
    });
  });
}
