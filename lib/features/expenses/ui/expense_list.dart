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
import 'day_label.dart';

/// Expenses under date headers (DESIGN.md §6 Lists), one panel per day.
/// [members] includes removed placeholders so old expenses keep names.
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.members,
    required this.meId,
  });

  final List<Expense> expenses;
  final List<Member> members;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final names = {for (final m in members) m.id: m.displayName};
    final days = byDay(expenses);
    return ListView(
      // Room for the FAB so it never covers the last row.
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 3),
      children: [
        for (final (day, list) in days) ...[
          SectionLabel(dayLabel(l10n, day)),
          Panel(
            children: [
              for (final e in list)
                ExpenseRow(expense: e, names: names, meId: meId),
            ],
          ),
        ],
      ],
    );
  }
}

/// Title + "Ali paid Rs 1,000" on the left, your part on the right.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.names,
    required this.meId,
  });

  final Expense expense;
  final Map<String, String> names;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _paidLine(l10n),
        style: muted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _MyPartText(part: myPart(expense, meId)),
    );
  }

  String _paidLine(AppLocalizations l10n) {
    final amount = formatRupees(expense.amount);
    if (expense.payers.length != 1) {
      // Multiple payers arrive in step 8; until then name the first.
      return l10n.expensePaidBy(names[expense.payers.keys.first] ?? '', amount);
    }
    final payer = expense.payers.keys.single;
    return payer == meId
        ? l10n.expenseYouPaid(amount)
        : l10n.expensePaidBy(names[payer] ?? '', amount);
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
