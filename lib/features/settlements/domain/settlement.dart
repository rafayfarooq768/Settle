import '../../../core/money/money.dart';

enum SettlementStatus { pending, confirmed }

/// `groups/{groupId}/settlements/{settlementId}` (PLAN.md §7).
/// "I paid" creates a pending one; the person paid confirms it, or records
/// a confirmed one directly. Only confirmed settlements change balances.
class Settlement {
  const Settlement({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.confirmedAt,
  });

  final String id;

  /// memberId who paid.
  final String from;

  /// memberId who was paid.
  final String to;
  final int amount;
  final SettlementStatus status;

  /// uid of the person who recorded it.
  final String createdBy;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  bool get isConfirmed => status == SettlementStatus.confirmed;

  LedgerSettlement toLedger() =>
      LedgerSettlement(from: from, to: to, amount: amount);
}
