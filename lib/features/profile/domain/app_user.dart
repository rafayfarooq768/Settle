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
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime createdAt;
  final List<PaymentMethod> paymentMethods;
}
