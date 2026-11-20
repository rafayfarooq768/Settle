import '../../settlements/domain/settlement.dart';
import 'expense.dart';

/// One row in a group's Expenses list: an expense or a confirmed payment
/// (owner's decision, 2026-11-20: payments show in the history).
sealed class TimelineItem {
  const TimelineItem();

  DateTime get at;
}

class ExpenseItem extends TimelineItem {
  const ExpenseItem(this.expense, {required this.settled});

  final Expense expense;

  /// Everyone was settled up after this expense: shown dimmed.
  final bool settled;

  @override
  DateTime get at => expense.date;
}

class PaymentItem extends TimelineItem {
  const PaymentItem(this.settlement);

  final Settlement settlement;

  /// When it was paid ("I paid" or recorded), not when it was confirmed.
  @override
  DateTime get at => settlement.createdAt;
}

/// Expenses covered by the last moment everyone in the group was at zero
/// (PLAN.md §4 nets, walked in date order). Computed every time, never
/// stored: an expense added later with an older date moves that moment.
/// Deleted and unbalanced expenses are left out, like in balances.
Set<String> settledExpenseIds(
  Iterable<Expense> expenses,
  Iterable<Settlement> settlements,
) {
  final events =
      <(DateTime, int, Object)>[
        for (final e in expenses)
          if (!e.deleted && e.isBalanced) (e.date, 0, e),
        // At the same instant, the expense counts before the payment.
        for (final s in settlements)
          if (s.isConfirmed) (s.createdAt, 1, s),
      ]..sort((a, b) {
        final byTime = a.$1.compareTo(b.$1);
        return byTime != 0 ? byTime : a.$2.compareTo(b.$2);
      });

  final nets = <String, int>{};
  void add(String id, int paisa) => nets[id] = (nets[id] ?? 0) + paisa;
  var lastZero = -1;
  for (var i = 0; i < events.length; i++) {
    switch (events[i].$3) {
      case final Expense e:
        e.payers.forEach(add);
        e.shares.forEach((id, paisa) => add(id, -paisa));
      case final Settlement s:
        add(s.from, s.amount);
        add(s.to, -s.amount);
    }
    if (nets.values.every((v) => v == 0)) lastZero = i;
  }
  return {
    for (var i = 0; i <= lastZero; i++)
      if (events[i].$3 case final Expense e) e.id,
  };
}

/// Expenses and confirmed payments grouped by calendar day, newest day
/// and newest item first (DESIGN.md §6 date headers). Deleted expenses
/// and pending payments are left out. With [where] (search), only the
/// expenses it keeps are listed and no payments; "settled" is still
/// worked out from all of them.
List<(DateTime day, List<TimelineItem> items)> timelineByDay(
  Iterable<Expense> expenses,
  Iterable<Settlement> settlements, {
  bool Function(Expense)? where,
}) {
  final settled = settledExpenseIds(expenses, settlements);
  final items = <TimelineItem>[
    for (final e in expenses)
      if (!e.deleted && (where == null || where(e)))
        ExpenseItem(e, settled: settled.contains(e.id)),
    if (where == null)
      for (final s in settlements)
        if (s.isConfirmed) PaymentItem(s),
  ]..sort((a, b) => b.at.compareTo(a.at));

  final days = <DateTime, List<TimelineItem>>{};
  for (final item in items) {
    final day = DateTime(item.at.year, item.at.month, item.at.day);
    (days[day] ??= []).add(item);
  }
  return [for (final d in days.keys) (d, days[d]!)];
}
