import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/profile/domain/payment_method.dart';
import 'package:settle/features/profile/domain/payment_methods.dart';

PaymentMethod m(String id, {bool preferred = false}) => PaymentMethod(
  id: id,
  name: id,
  accountTitle: 'Ali',
  accountNumber: '0300',
  preferred: preferred,
);

void main() {
  test('adding appends; editing replaces in place', () {
    final list = saveMethod([m('a'), m('b')], m('c'));
    expect(list.map((x) => x.id), ['a', 'b', 'c']);
    final edited = saveMethod(list, m('b').copyWith(name: 'Meezan'));
    expect(edited.map((x) => x.id), ['a', 'b', 'c']);
    expect(edited[1].name, 'Meezan');
  });

  test('only one method is preferred', () {
    final list = saveMethod([
      m('a', preferred: true),
      m('b'),
    ], m('b', preferred: true));
    expect(list.where((x) => x.preferred).map((x) => x.id), ['b']);
  });

  test('saving a non-preferred method keeps the preferred one', () {
    final list = saveMethod([m('a', preferred: true)], m('b'));
    expect(list.where((x) => x.preferred).map((x) => x.id), ['a']);
  });

  test('remove drops only that id', () {
    expect(removeMethod([m('a'), m('b')], 'a').map((x) => x.id), ['b']);
  });

  test('preferred comes first when paying, the rest keep their order', () {
    final list = [m('a'), m('b'), m('c', preferred: true)];
    expect(forPaying(list).map((x) => x.id), ['c', 'a', 'b']);
  });

  test('new ids are 12 lowercase letters or digits', () {
    final id = newPaymentMethodId(random: Random(1));
    expect(id, matches(RegExp(r'^[a-z0-9]{12}$')));
  });
}
