import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/phone/phone_number.dart';

void main() {
  group('normalizePhone', () {
    test('the usual ways to type a Pakistani mobile all match', () {
      for (final typed in [
        '03001234567',
        '0300 1234567',
        '0300-1234567',
        '300 1234567',
        '+92 300 1234567',
        '+92-300-1234567',
        '0092 300 1234567',
        '923001234567',
        ' (0300) 123.4567 ',
      ]) {
        expect(normalizePhone(typed), '+923001234567', reason: typed);
      }
    });

    test('other countries need a + or 00', () {
      expect(normalizePhone('+971 50 123 4567'), '+971501234567');
      expect(normalizePhone('00971501234567'), '+971501234567');
      expect(normalizePhone('971501234567'), isNull);
    });

    test('rejects what cannot be a number', () {
      for (final typed in [
        '',
        '   ',
        'abc',
        '0300 12345', // too short
        '0300 12345678', // too long
        '+92 21 1234567', // a landline, not on WhatsApp as a PK mobile
        '+12', // too short
        '+0300123456',
        '0300123456a',
      ]) {
        expect(normalizePhone(typed), isNull, reason: typed);
      }
    });
  });

  test('formatPhone groups Pakistani mobiles', () {
    expect(formatPhone('+923001234567'), '+92 300 1234567');
    expect(formatPhone('+971501234567'), '+971501234567');
    expect(formatPhone(''), '');
  });

  test('whatsAppDigits drops the plus', () {
    expect(whatsAppDigits('+923001234567'), '923001234567');
    expect(whatsAppDigits(''), isNull);
  });
}
