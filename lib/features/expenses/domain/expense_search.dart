import 'expense.dart';

/// [memberId] paid for or has a share in [e].
bool involves(Expense e, String memberId) =>
    (e.payers[memberId] ?? 0) > 0 || (e.shares[memberId] ?? 0) > 0;

/// Whether [e] matches a search (PLAN.md §3 item 7): [query] in the title
/// or note (any case), only expenses [involving] that member, only
/// [month] (year and month of its date). Deleted expenses never match.
bool matchesSearch(
  Expense e, {
  String query = '',
  String? involving,
  DateTime? month,
}) {
  if (e.deleted) return false;
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty &&
      !e.title.toLowerCase().contains(q) &&
      !e.note.toLowerCase().contains(q)) {
    return false;
  }
  if (involving != null && !involves(e, involving)) return false;
  if (month != null &&
      (e.date.year != month.year || e.date.month != month.month)) {
    return false;
  }
  return true;
}

/// The months that have expenses, newest first, for the month filter.
List<DateTime> expenseMonths(Iterable<Expense> expenses) {
  final months = {
    for (final e in expenses)
      if (!e.deleted) DateTime(e.date.year, e.date.month),
  }.toList()..sort((a, b) => b.compareTo(a));
  return months;
}
