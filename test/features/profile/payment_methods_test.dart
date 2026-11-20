import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/profile/domain/payment_method.dart';
import 'package:settle/features/profile/domain/payment_methods.dart';

PaymentMethod m(String id) =>
    PaymentMethod(id: id, name: id, accountTitle: 'Ali', accountNumber: '0300');

void main() {
  test('adding appends; editing replaces in place', () {
    final list = saveMethod([m('a'), m('b')], m('c'));
    expect(list.map((x) => x.id), ['a', 'b', 'c']);
    final edited = saveMethod(list, m('b').copyWith(name: 'Meezan'));
    expect(edited.map((x) => x.id), ['a', 'b', 'c']);
    expect(edited[1].name, 'Meezan');
  });

  test('remove drops only that id', () {
    expect(removeMethod([m('a'), m('b')], 'a').map((x) => x.id), ['b']);
  });

  test('new ids are 12 lowercase letters or digits', () {
    final id = newPaymentMethodId(random: Random(1));
    expect(id, matches(RegExp(r'^[a-z0-9]{12}$')));
  });
}
