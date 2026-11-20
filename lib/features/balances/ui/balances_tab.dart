import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../../expenses/domain/monthly_summary.dart';
import '../../expenses/ui/expenses_providers.dart';
import '../domain/balance_rows.dart';
import 'balances_providers.dart';

/// Every member's net in the group, largest owed → largest owes
/// (DESIGN.md §11). Computed from expenses + confirmed settlements.
class BalancesTab extends ConsumerWidget {
  const BalancesTab({super.key, required this.groupId, required this.me});

  final String groupId;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nets = ref.watch(groupNetsProvider(groupId));
    final members = ref.watch(membersProvider(groupId)).valueOrNull ?? [];
    return nets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => TabMessage(errorText(l10n, e)),
      data: (nets) => ListView(
        // Room under "By month" so the FAB never covers it.
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.fabClearance,
        ),
        children: [
          Panel(
            dividerIndent: avatarRowDividerIndent,
            children: [
              for (final m in balanceRows(members, nets))
                ListTile(
                  minTileHeight: AppSpacing.rowHeight,
                  leading: MemberAvatar(
                    name: m.displayName,
                    placeholder: m.isPlaceholder,
                  ),
                  title: Text(
                    m.id == me.id
                        ? l10n.memberYou(m.displayName)
                        : m.displayName,
                  ),
                  trailing: BalanceStack(
                    net: nets[m.id] ?? 0,
                    wording: m.id == me.id
                        ? BalanceWording.you
                        : BalanceWording.member,
                  ),
                ),
            ],
          ),
          _ByMonth(groupId: groupId, meId: me.id),
        ],
      ),
    );
  }
}

/// What the group spent each month and your share (PLAN.md §3 item 13):
/// numbers only, no chart. Nothing when there are no expenses yet.
class _ByMonth extends ConsumerWidget {
  const _ByMonth({required this.groupId, required this.meId});

  final String groupId;
  final String meId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final expenses = ref.watch(expensesProvider(groupId)).valueOrNull ?? [];
    final months = monthlyTotals(expenses, meId);
    if (months.isEmpty) return const SizedBox.shrink();
    final format = DateFormat.yMMMM(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l10n.byMonthSection),
        Panel(
          dividerIndent: AppSpacing.lg,
          children: [
            for (final m in months)
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                title: Text(format.format(m.month)),
                subtitle: Text(
                  l10n.monthGroupSpent(formatRupees(m.total)),
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                // Your share isn't a debt, so no money colour.
                trailing: m.myShare == 0
                    ? MoneyStack(label: l10n.monthNotInvolved, color: muted)
                    : _YourShare(amount: m.myShare),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Your share" (muted) over the amount, laid out like the money label.
class _YourShare extends StatelessWidget {
  const _YourShare({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          l10n.monthYourShare,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(formatRupees(amount), style: rowAmountStyle(theme)),
      ],
    );
  }
}
