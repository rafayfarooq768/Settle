import '../../profile/domain/payment_method.dart';

/// `groups/{groupId}` (PLAN.md §7).
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.joinCode,
    required this.memberUids,
    this.currency = 'PKR',
  });

  final String id;
  final String name;

  /// Free text with suggestions (PLAN.md §6).
  final String type;

  /// uid of the creator; only they can regenerate the join code.
  final String createdBy;
  final DateTime createdAt;
  final String joinCode;
  final String currency;

  /// Real users only (placeholders have no uid). Used by security rules.
  final List<String> memberUids;
}

/// `groups/{groupId}/members/{memberId}`. Expenses always refer to memberId,
/// so placeholders and real members work the same way (PLAN.md §7).
class Member {
  const Member({
    required this.id,
    required this.displayName,
    required this.joinedAt,
    this.uid,
    this.claimedAt,
    this.active = true,
    this.paymentMethods = const [],
  });

  final String id;
  final String displayName;

  /// Null for a placeholder (added by name, not joined yet).
  final String? uid;
  final DateTime? claimedAt;
  final DateTime joinedAt;
  final bool active;

  /// Copy of the member's own payment methods, so group-mates can see them
  /// at settle-up (PLAN.md §5) without reading their private users doc.
  final List<PaymentMethod> paymentMethods;

  bool get isPlaceholder => uid == null;
}
