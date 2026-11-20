import 'expense.dart';
import 'expense_summary.dart';

/// How far back the duplicate guard looks (PLAN.md §3 item 7).
const Duration duplicateWindow = Duration(minutes: 10);

/// An expense added in the last [window] with the same amount and the same
/// people as [draft], or null. "The same people" means the same set of
/// members with a share; who paid doesn't matter, since a friend adding
/// the same bill from their own phone usually picks themselves as payer.
/// Deleted expenses don't count.
Expense? findDuplicate(
  Iterable<Expense> existing,
  ExpenseDraft draft, {
  required DateTime now,
  Duration window = duplicateWindow,
}) {
  final people = _people(draft.shares);
  Expense? newest;
  for (final e in existing) {
    if (e.deleted || e.amount != draft.amount) continue;
    final age = now.difference(e.createdAt);
    if (age.isNegative ? age.abs() > window : age > window) continue;
    if (!_sameSet(_people(e.shares), people)) continue;
    if (newest == null || e.createdAt.isAfter(newest.createdAt)) newest = e;
  }
  return newest;
}

Set<String> _people(Map<String, int> shares) => {
  for (final MapEntry(:key, :value) in shares.entries)
    if (value > 0) key,
};

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
