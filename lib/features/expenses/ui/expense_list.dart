import 'package:material_ui/material_ui.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/row_chevron.dart';
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
    this.onOpen,
    this.where,
  });

  /// Only the expenses this keeps (search), and no payments.
  final bool Function(Expense)? where;

  /// Opens an expense's detail screen.
  final ValueChanged<Expense>? onOpen;

  final List<Expense> expenses;
  final List<Settlement> settlements;
  final List<Member> members;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final names = {for (final m in members) m.id: m.displayName};
    final days = timelineByDay(expenses, settlements, where: where);
    // One item per day, built only as it scrolls into view, so a group
    // with hundreds of expenses opens fast on a cheap phone.
    return ListView.builder(
      // Room for the FAB so it never covers the last row.
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final (day, list) = days[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      onTap: onOpen == null ? null : () => onOpen!(expense),
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
        );
      },
    );
  }
}

/// The muted line under a row's title. Wraps rather than cutting off an
/// amount, and says when the row hasn't reached the server yet.
class _Subtitle extends StatelessWidget {
  const _Subtitle({
    required this.text,
    required this.style,
    required this.pendingSync,
  });

  final String text;
  final TextStyle? style;
  final bool pendingSync;

  @override
  Widget build(BuildContext context) {
    if (!pendingSync) return Text(text, style: style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: style),
        Text(AppLocalizations.of(context)!.notSyncedYet, style: style),
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
    this.onTap,
  });

  final VoidCallback? onTap;
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
      contentPadding: chevronRowPadding,
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
      // Carries an amount, so it wraps instead of ending in "…" when the
      // font is large (PRODUCT.md: never wrong about money).
      subtitle: _Subtitle(
        text: _paidLine(l10n),
        style: muted,
        pendingSync: expense.pendingSync,
      ),
      // The chevron says the row opens the expense (DESIGN.md §6).
      trailing: RowEnd(
        opens: onTap != null,
        child: settled
            ? MoneyStack(
                label: l10n.rowSettledExpense,
                color: context.extraColors.settled,
              )
            : _MyPart(part: myPart(expense, meId)),
      ),
      onTap: onTap,
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
      subtitle: _Subtitle(
        text: l10n.paymentRowLabel,
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        pendingSync: s.pendingSync,
      ),
      contentPadding: chevronRowPadding,
      // Doesn't open anything, but keeps the chevron's space so its
      // amount lines up with the expenses above and below.
      trailing: RowEnd(
        opens: false,
        child: Text(formatRupees(s.amount), style: rowAmountStyle(theme)),
      ),
    );
  }
}

/// Your part of an expense, as a [MoneyStack]: "You owe" / "You lent"
/// over the amount, or one quiet line.
class _MyPart extends StatelessWidget {
  const _MyPart({required this.part});

  final MyPart part;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    final muted = theme.colorScheme.onSurfaceVariant;
    return switch (part) {
      Owe(:final amount) => MoneyStack(
        label: l10n.stackYouOwe,
        amount: amount,
        color: money.owe,
      ),
      Lent(:final amount) => MoneyStack(
        label: l10n.stackYouLent,
        amount: amount,
        color: money.owed,
      ),
      Even() => MoneyStack(label: l10n.rowEven, color: muted),
      NotInvolved() => MoneyStack(label: l10n.rowNotInvolved, color: muted),
    };
  }
}
