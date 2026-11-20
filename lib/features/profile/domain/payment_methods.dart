import 'dart:math';

import 'payment_method.dart';

/// Firestore rules allow at most this many per person.
const maxPaymentMethods = 20;

/// A short random id for a new method (ids only need to be unique within
/// one person's list).
String newPaymentMethodId({Random? random}) {
  final rng = random ?? Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes(
    List.generate(12, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

/// [list] with [method] added, or replacing the one with its id. Only one
/// method is preferred: marking this one clears the others.
List<PaymentMethod> saveMethod(List<PaymentMethod> list, PaymentMethod method) {
  PaymentMethod plain(PaymentMethod m) =>
      method.preferred && m.preferred ? m.copyWith(preferred: false) : m;
  final i = list.indexWhere((m) => m.id == method.id);
  return [
    for (final m in list) m.id == method.id ? method : plain(m),
    if (i < 0) method,
  ];
}

/// [list] without the method with [id].
List<PaymentMethod> removeMethod(List<PaymentMethod> list, String id) => [
  for (final m in list)
    if (m.id != id) m,
];

/// The order shown to someone paying: preferred first, then as added.
List<PaymentMethod> forPaying(List<PaymentMethod> list) => [
  ...list.where((m) => m.preferred),
  ...list.where((m) => !m.preferred),
];
