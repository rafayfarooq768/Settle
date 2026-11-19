/// A way to pay someone (PLAN.md §5). Free text on purpose: no format checks.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.accountTitle,
    required this.accountNumber,
    this.preferred = false,
  });

  final String id;

  /// e.g. "Meezan Bank", "NayaPay", "JazzCash".
  final String name;
  final String accountTitle;

  /// Account number, IBAN or Raast ID.
  final String accountNumber;
  final bool preferred;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'accountTitle': accountTitle,
    'accountNumber': accountNumber,
    'preferred': preferred,
  };

  static PaymentMethod fromMap(Map<String, Object?> map) => PaymentMethod(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    accountTitle: map['accountTitle'] as String? ?? '',
    accountNumber: map['accountNumber'] as String? ?? '',
    preferred: map['preferred'] as bool? ?? false,
  );

  static List<PaymentMethod> listFrom(Object? raw) => [
    for (final item in (raw as List?) ?? const [])
      if (item is Map) fromMap(Map<String, Object?>.from(item)),
  ];
}
