import 'payment_method.dart';

/// `users/{uid}` (PLAN.md §7). Only the owner can read or write it; payment
/// methods are copied onto the user's member docs so group-mates can see them.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.paymentMethods = const [],
    this.phone = '',
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime createdAt;
  final List<PaymentMethod> paymentMethods;

  /// Optional, not verified ("+923001234567", or empty). Copied onto member
  /// docs so group-mates' WhatsApp reminders open this chat.
  final String phone;
}
