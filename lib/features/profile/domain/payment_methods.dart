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

/// [list] with [method] added at the end, or replacing the one with its id.
List<PaymentMethod> saveMethod(
  List<PaymentMethod> list,
  PaymentMethod method,
) => [
  for (final m in list) m.id == method.id ? method : m,
  if (!list.any((m) => m.id == method.id)) method,
];

/// [list] without the method with [id].
List<PaymentMethod> removeMethod(List<PaymentMethod> list, String id) => [
  for (final m in list)
    if (m.id != id) m,
];
