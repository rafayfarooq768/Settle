/// Thrown when money input breaks a PLAN.md §4 rule (e.g. shares that don't
/// sum to the total). UI validates before calling, so this signals a bug or
/// bad stored data, not normal user input.
class MoneyException implements Exception {
  const MoneyException(this.message);

  final String message;

  @override
  String toString() => 'MoneyException: $message';
}
