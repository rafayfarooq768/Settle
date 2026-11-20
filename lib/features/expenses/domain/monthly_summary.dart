import 'expense.dart';

/// One month of a group (PLAN.md §3 item 13): what everyone spent and
/// your part of it, in paisa.
class MonthTotal {
  const MonthTotal({
    required this.month,
    required this.total,
    required this.myShare,
  });

  /// The first of the month.
  final DateTime month;
  final int total;
  final int myShare;
}

/// Totals by month, newest first, computed from the expenses every time
/// (never stored). Deleted and unbalanced expenses are left out, like in
/// balances; payments aren't spending, so they don't count.
List<MonthTotal> monthlyTotals(Iterable<Expense> expenses, String meId) {
  final totals = <DateTime, (int, int)>{};
  for (final e in expenses) {
    if (e.deleted || !e.isBalanced) continue;
    final month = DateTime(e.date.year, e.date.month);
    final (total, mine) = totals[month] ?? (0, 0);
    totals[month] = (total + e.amount, mine + (e.shares[meId] ?? 0));
  }
  final months = totals.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final m in months)
      MonthTotal(month: m, total: totals[m]!.$1, myShare: totals[m]!.$2),
  ];
}
