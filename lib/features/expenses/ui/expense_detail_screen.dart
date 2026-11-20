import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../activity/ui/activity_providers.dart';
import '../../activity/ui/activity_screen.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/expense.dart';
import '../domain/expense_summary.dart';
import 'day_label.dart';
import 'expenses_providers.dart';
import 'split_screen.dart' show memberName;

/// One expense (DESIGN.md §8 screen 6): the amount, who paid, who owes
/// what, and its history. Edit is in the app bar; Delete is owe-red text
/// at the bottom and comes with Undo instead of a confirmation (§8).
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });

  final String groupId;
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expenses = ref.watch(expensesProvider(groupId));
    final expense = expenses.valueOrNull
        ?.where((e) => e.id == expenseId)
        .firstOrNull;
    final me = ref.watch(myMemberProvider(groupId)).valueOrNull;
    final members = ref.watch(membersProvider(groupId)).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(expense?.title ?? ''),
        actions: [
          if (expense != null && !expense.deleted && me != null)
            IconButton(
              tooltip: l10n.editTooltip,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('/groups/$groupId/expenses/$expenseId/edit'),
            ),
        ],
      ),
      body: switch ((expenses, expense, me)) {
        (AsyncError(:final error), _, _) => TabMessage(errorText(l10n, error)),
        (AsyncData(), null, _) => TabMessage(l10n.expenseNotFound),
        (_, final Expense e, final Member m) => _Body(
          groupId: groupId,
          expense: e,
          me: m,
          members: members,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.groupId,
    required this.expense,
    required this.me,
    required this.members,
  });

  final String groupId;
  final Expense expense;
  final Member me;
  final List<Member> members;

  String _splitLabel(AppLocalizations l10n) => switch (expense.splitMode) {
    SplitMode.equal => l10n.detailSplitEqual,
    SplitMode.exact => l10n.detailSplitExact,
    SplitMode.percent => l10n.detailSplitPercent,
    SplitMode.itemized => l10n.detailSplitItems,
  };

  /// [amounts] as rows in group order, nobody with 0.
  List<Widget> _rows(AppLocalizations l10n, Map<String, int> amounts) => [
    for (final m in members)
      if ((amounts[m.id] ?? 0) > 0)
        _AmountRow(
          member: m,
          name: memberName(l10n, m, me.id),
          amount: amounts[m.id]!,
        ),
  ];

  Future<void> _setDeleted(
    BuildContext context,
    WidgetRef ref, {
    required bool deleted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(expenseRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    Future<void> apply(bool value) => repo.setDeleted(
      groupId: groupId,
      actorMemberId: me.id,
      expense: expense,
      deleted: value,
    );
    try {
      await apply(deleted);
    } catch (e) {
      messenger.showMessage(errorText(l10n, e));
      return;
    }
    if (deleted) {
      // Back to the list, where the row is gone; Undo brings it back.
      messenger.showMessage(
        l10n.expenseDeleted,
        undoLabel: l10n.undoButton,
        onUndo: () => apply(false),
      );
      if (context.mounted) context.pop();
    } else {
      messenger.showMessage(l10n.expenseRestored);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history =
        ref
            .watch(
              targetActivityProvider((groupId: groupId, targetId: expense.id)),
            )
            .valueOrNull ??
        const [];

    return ScreenLayout(
      padded: false,
      body: [
        const SizedBox(height: AppSpacing.lg),
        _Header(expense: expense, me: me, members: members),
        SectionLabel(l10n.detailPaidBy),
        Panel(
          dividerIndent: avatarRowDividerIndent,
          children: _rows(l10n, expense.payers),
        ),
        SectionLabel(_splitLabel(l10n)),
        Panel(
          dividerIndent: avatarRowDividerIndent,
          children: _rows(l10n, expense.shares),
        ),
        if (history.isNotEmpty) ...[
          SectionLabel(l10n.detailHistory),
          Panel(
            dividerIndent: avatarRowDividerIndent,
            children: [
              for (final a in history)
                ActivityRow(activity: a, members: members, meId: me.id),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
      actions: [
        if (expense.deleted)
          LoadingButton(
            label: l10n.restoreExpenseButton,
            style: LoadingButtonStyle.text,
            onPressed: () => _setDeleted(context, ref, deleted: false),
          )
        else
          LoadingButton(
            label: l10n.deleteExpenseButton,
            style: LoadingButtonStyle.text,
            foregroundColor: context.moneyColors.owe,
            onPressed: () => _setDeleted(context, ref, deleted: true),
          ),
      ],
    );
  }
}

/// Straight on the background like the Group header (DESIGN.md §11): the
/// amount is the one big number, then when and who added it, then your
/// part in words and colour.
class _Header extends StatelessWidget {
  const _Header({
    required this.expense,
    required this.me,
    required this.members,
  });

  final Expense expense;
  final Member me;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final money = context.moneyColors;
    final adder = members.where((m) => m.uid == expense.createdBy).firstOrNull;
    final adderName = adder == null
        ? l10n.activitySomeone
        : adder.id == me.id
        ? l10n.youLabel.toLowerCase()
        : adder.displayName;

    final (part, partColor) = expense.deleted
        ? (l10n.detailDeleted, muted)
        : switch (myPart(expense, me.id)) {
            Owe(:final amount) => (
              l10n.detailYouOwe(formatRupees(amount)),
              money.owe,
            ),
            Lent(:final amount) => (
              l10n.detailYouLent(formatRupees(amount)),
              money.owed,
            ),
            Even() => (l10n.detailPaidShare, muted),
            NotInvolved() => (l10n.detailNotInvolved, muted),
          };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BigAmount(
            paisa: expense.amount,
            style: theme.textTheme.headlineLarge,
            color: expense.deleted ? muted : theme.colorScheme.onSurface,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.detailAddedBy(dayLabel(l10n, expense.date), adderName),
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            part,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: partColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar, name and an amount: who paid or who owes.
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.member,
    required this.name,
    required this.amount,
  });

  final Member member;
  final String name;
  final int amount;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: AppSpacing.rowHeight,
    leading: MemberAvatar(
      name: member.displayName,
      placeholder: member.isPlaceholder,
    ),
    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Text(
      formatRupees(amount),
      style: rowAmountStyle(Theme.of(context)),
    ),
  );
}
