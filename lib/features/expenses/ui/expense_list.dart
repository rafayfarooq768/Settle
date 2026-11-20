import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../domain/expense.dart';
import '../domain/expense_summary.dart';
import '../domain/timeline.dart';
import '../../settlements/domain/settlement.dart';
import 'day_label.dart';

/// Expenses and confirmed payments under date headers (DESIGN.md §6
/// Lists), one panel per day. [members] includes removed placeholders so
/// old expenses keep names.
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.settlements,
    required this.members,
    required this.meId,
  });

  final List<Expense> expenses;
  final List<Settlement> settlements;
  final List<Member> members;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final names = {for (final m in members) m.id: m.displayName};
    final days = timelineByDay(expenses, settlements);
    return ListView(
      // Room for the FAB so it never covers the last row.
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 3),
      children: [
        for (final (day, list) in days) ...[
          SectionLabel(dayLabel(l10n, day)),
          Panel(
            children: [
              for (final item in list)
                switch (item) {
                  ExpenseItem(:final expense, :final settled) => ExpenseRow(
                    expense: expense,
                    names: names,
                    meId: meId,
                    settled: settled,
                  ),
                  PaymentItem(:final settlement) => PaymentRow(
                    settlement: settlement,
                    names: names,
                    meId: meId,
                  ),
                },
            ],
          ),
        ],
      ],
    );
  }
}

/// Title + "Ali paid Rs 1,000" on the left, your part on the right.
/// Once everyone has settled up after it, the row is dimmed and says
/// "settled" instead of your part.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.names,
    required this.meId,
    this.settled = false,
  });

  final Expense expense;
  final Map<String, String> names;
  final String meId;
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: settled
            ? theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: Text(
        _paidLine(l10n),
        style: muted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: settled
          ? Text(
              l10n.rowSettledExpense,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.extraColors.settled,
              ),
            )
          : _MyPartText(part: myPart(expense, meId)),
    );
  }

  String _paidLine(AppLocalizations l10n) {
    final amount = formatRupees(expense.amount);
    if (expense.payers.length != 1) {
      return l10n.expenseManyPaid(expense.payers.length, amount);
    }
    final payer = expense.payers.keys.single;
    return payer == meId
        ? l10n.expenseYouPaid(amount)
        : l10n.expensePaidBy(names[payer] ?? '', amount);
  }
}

/// A confirmed payment in the history: "Ali paid you" / "You paid Ali" /
/// "Bilal paid Ali", "Payment" under it, the amount on the right. Plain,
/// not owe/owed colours: a payment evens things out, it isn't a debt.
class PaymentRow extends StatelessWidget {
  const PaymentRow({
    super.key,
    required this.settlement,
    required this.names,
    required this.meId,
  });

  final Settlement settlement;
  final Map<String, String> names;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final s = settlement;
    final from = names[s.from] ?? '';
    final to = names[s.to] ?? '';
    final text = s.from == meId
        ? l10n.paymentRowYouPaid(to)
        : s.to == meId
        ? l10n.paymentRowPaidYou(from)
        : l10n.paymentRowPaid(from, to);
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.paymentRowLabel,
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      ),
      trailing: Text(
        formatRupees(s.amount),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MyPartText extends StatelessWidget {
  const _MyPartText({required this.part});

  final MyPart part;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    final muted = theme.colorScheme.onSurfaceVariant;
    final (text, color) = switch (part) {
      Owe(:final amount) => (l10n.rowYouOwe(formatRupees(amount)), money.owe),
      Lent(:final amount) => (
        l10n.rowYouLent(formatRupees(amount)),
        money.owed,
      ),
      Even() => (l10n.rowEven, muted),
      NotInvolved() => (l10n.rowNotInvolved, muted),
    };
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}
