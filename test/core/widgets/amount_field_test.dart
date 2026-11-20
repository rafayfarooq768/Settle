import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/core/widgets/amount_field.dart';

String _type(String before, String typed) => RupeeInputFormatter()
    .formatEditUpdate(
      TextEditingValue(text: before),
      TextEditingValue(text: typed),
    )
    .text;

void main() {
  test('groups thousands as you type', () {
    expect(_type('', '1'), '1');
    expect(_type('100', '1000'), '1,000');
    expect(_type('1,000', '1,0000'), '10,000');
    expect(_type('', '1234567'), '1,234,567');
  });

  test('keeps one dot and at most 2 decimals', () {
    expect(_type('1,200', '1,200.'), '1,200.');
    expect(_type('1,200.5', '1,200.50'), '1,200.50');
    expect(_type('1,200.50', '1,200.505'), '1,200.50');
    expect(_type('12.5', '12.5.'), '12.5');
  });

  test('drops leading zeros and letters', () {
    expect(_type('0', '05'), '5');
    expect(_type('', 'Rs 50a'), '50');
    expect(_type('', '0.5'), '0.5');
  });

  test('what it shows parses back to the same paisa', () {
    expect(parseRupees(_type('', '1234567.89')), 123456789);
  });
}
