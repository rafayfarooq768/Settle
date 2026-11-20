/// A way to pay someone (PLAN.md §5). Free text on purpose: no format checks.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.accountTitle,
    required this.accountNumber,
  });

  final String id;

  /// e.g. "Meezan Bank", "Nayapay", "JazzCash".
  final String name;
  final String accountTitle;

  /// Account number, IBAN or Raast ID.
  final String accountNumber;

  PaymentMethod copyWith({
    String? name,
    String? accountTitle,
    String? accountNumber,
  }) => PaymentMethod(
    id: id,
    name: name ?? this.name,
    accountTitle: accountTitle ?? this.accountTitle,
    accountNumber: accountNumber ?? this.accountNumber,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'accountTitle': accountTitle,
    'accountNumber': accountNumber,
  };

  static PaymentMethod fromMap(Map<String, Object?> map) => PaymentMethod(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    accountTitle: map['accountTitle'] as String? ?? '',
    accountNumber: map['accountNumber'] as String? ?? '',
  );

  static List<PaymentMethod> listFrom(Object? raw) => [
    for (final item in (raw as List?) ?? const [])
      if (item is Map) fromMap(Map<String, Object?>.from(item)),
  ];
}
