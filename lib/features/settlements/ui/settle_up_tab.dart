import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/row_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/settle_up.dart';
import '../domain/settlement.dart';
import 'settle_actions.dart';
import 'settlements_providers.dart';

/// Settle up (PLAN.md §3 items 9–11, DESIGN.md §11). "Your payments" on
/// top, one row per person: a pending "I paid" sits in that person's row
/// and replaces its actions until it's confirmed, refused or cancelled.
/// Then everyone else's payments.
class SettleUpTab extends ConsumerWidget {
  const SettleUpTab({super.key, required this.group, required this.me});

  final Group group;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nets = ref.watch(groupNetsProvider(group.id));
    final members = ref.watch(membersProvider(group.id)).valueOrNull ?? [];
    final settlements =
        ref.watch(settlementsProvider(group.id)).valueOrNull ?? [];
    final byId = {for (final m in members) m.id: m};

    return nets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => TabMessage(errorText(l10n, e)),
      data: (nets) {
        final list = settleUpList(
          nets,
          meId: me.id,
          order: [for (final m in members) m.id],
        );
        final pending = pendingForMe(settlements, me.id);
        if (list.isEmpty && pending.isEmpty) {
          return TabMessage(
            l10n.settleEveryoneSettled,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.extraColors.settled,
            ),
          );
        }
        final actions = SettleActions(context, ref, group: group, me: me);

        // Pair each pending payment with that person's row; the ones with
        // no row (balances moved on) get a row of their own.
        final toConfirm = [...pending.toConfirm];
        final waiting = [...pending.waiting];
        Settlement? take(List<Settlement> from, bool Function(Settlement) f) {
          final i = from.indexWhere(f);
          return i < 0 ? null : from.removeAt(i);
        }

        final transferRows = [
          for (final t in list.mine)
            _TransferRow(
              transfer: t,
              meId: me.id,
              members: byId,
              actions: actions,
              pending: t.to == me.id
                  ? take(toConfirm, (s) => s.from == t.from)
                  : take(waiting, (s) => s.to == t.to),
            ),
        ];
        final mine = [
          for (final s in [...toConfirm, ...waiting])
            _PendingRow(
              settlement: s,
              meId: me.id,
              members: byId,
              actions: actions,
            ),
          ...transferRows,
        ];

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 3),
          children: [
            if (mine.isNotEmpty) ...[
              SectionLabel(l10n.settleYoursLabel),
              Panel(dividerIndent: avatarRowDividerIndent, children: mine),
            ],
            if (list.others.isNotEmpty) ...[
              SectionLabel(l10n.settleOthersLabel),
              Panel(
                dividerIndent: avatarRowDividerIndent,
                children: [
                  for (final t in list.others)
                    _TransferRow(transfer: t, meId: me.id, members: byId),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A settle-up row: avatar, money line (+ status), amount, and the row's
/// text actions lined up under the money line.
class _Row extends StatelessWidget {
  const _Row({
    required this.face,
    required this.title,
    required this.amount,
    this.amountColor,
    this.status,
    this.actions = const [],
  });

  final Member? face;
  final String title;
  final int amount;
  final Color? amountColor;

  /// Muted line under the money line, e.g. "Says they paid Rs 100".
  final String? status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          minTileHeight: AppSpacing.rowHeight,
          leading: MemberAvatar(
            name: face?.displayName ?? '',
            placeholder: face?.isPlaceholder ?? false,
          ),
          title: Text(title),
          subtitle: status == null ? null : Text(status!),
          trailing: Text(
            formatRupees(amount),
            style: theme.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: avatarRowDividerIndent - RowButton.inset,
              end: AppSpacing.lg,
            ),
            child: Transform.translate(
              // Pull the actions up under the text they belong to.
              offset: const Offset(0, -AppSpacing.sm),
              child: Wrap(spacing: AppSpacing.xs, children: actions),
            ),
          ),
      ],
    );
  }
}

/// "You pay Ali" → I paid, or (waiting) Cancel payment.
/// "Ali pays you" → Record payment, Remind; or (Ali says they paid)
/// Confirm, Not received. "Bilal pays Ali" has no actions.
/// Words carry the direction; colour only backs them up (DESIGN.md §2).
class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.meId,
    required this.members,
    this.actions,
    this.pending,
  });

  final Transfer transfer;
  final String meId;
  final Map<String, Member> members;

  /// Null for other people's rows.
  final SettleActions? actions;

  /// The pending "I paid" between the two, if any.
  final Settlement? pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final money = context.moneyColors;
    final t = transfer;
    final from = members[t.from];
    final to = members[t.to];
    final act = actions;
    final p = pending;

    if (t.from == meId) {
      final name = to?.displayName ?? '';
      return _Row(
        face: to,
        title: l10n.transferYouPay(name),
        amount: t.amount,
        amountColor: money.owe,
        status: p == null
            ? null
            : l10n.pendingWaitingAmount(name, formatRupees(p.amount)),
        actions: [
          if (act != null && p != null)
            _cancel(l10n, act, p)
          else if (act != null && to != null)
            RowButton(
              label: l10n.iPaidButton,
              onPressed: () => act.pay(to: to, owed: t.amount),
            ),
        ],
      );
    }
    if (t.to == meId) {
      return _Row(
        face: from,
        title: l10n.transferPaysYou(from?.displayName ?? ''),
        amount: t.amount,
        amountColor: money.owed,
        status: p == null
            ? null
            : l10n.pendingSaysPaidAmount(formatRupees(p.amount)),
        actions: [
          if (act != null && p != null)
            ..._confirmOrRefuse(l10n, act, p)
          else if (act != null && from != null) ...[
            RowButton(
              label: l10n.recordPaymentButton,
              onPressed: () => act.record(from: from, owed: t.amount),
            ),
            RowButton(
              label: l10n.remindButton,
              kind: RowButtonKind.secondary,
              onPressed: () => act.remind(who: from, owed: t.amount),
            ),
          ],
        ],
      );
    }
    return _Row(
      face: from,
      title: l10n.transferPays(from?.displayName ?? '', to?.displayName ?? ''),
      amount: t.amount,
    );
  }
}

/// A pending "I paid" that no longer matches a row in the list.
class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.settlement,
    required this.meId,
    required this.members,
    required this.actions,
  });

  final Settlement settlement;
  final String meId;
  final Map<String, Member> members;
  final SettleActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = settlement;
    if (s.to == meId) {
      final from = members[s.from];
      return _Row(
        face: from,
        title: l10n.pendingSaysPaidYou(from?.displayName ?? ''),
        amount: s.amount,
        amountColor: context.moneyColors.owed,
        actions: _confirmOrRefuse(l10n, actions, s),
      );
    }
    final to = members[s.to];
    final name = to?.displayName ?? '';
    return _Row(
      face: to,
      title: l10n.pendingYouPaid(name),
      status: l10n.pendingWaitingFor(name),
      amount: s.amount,
      amountColor: Theme.of(context).colorScheme.onSurfaceVariant,
      actions: [_cancel(l10n, actions, s)],
    );
  }
}

List<Widget> _confirmOrRefuse(
  AppLocalizations l10n,
  SettleActions actions,
  Settlement s,
) => [
  RowButton(label: l10n.confirmButton, onPressed: () => actions.confirm(s)),
  RowButton(
    label: l10n.notReceivedButton,
    kind: RowButtonKind.secondary,
    onPressed: () => actions.remove(s, done: l10n.paymentNotReceived),
  ),
];

Widget _cancel(AppLocalizations l10n, SettleActions actions, Settlement s) =>
    RowButton(
      label: l10n.cancelPaymentButton,
      kind: RowButtonKind.secondary,
      onPressed: () => actions.remove(s, done: l10n.paymentCancelled),
    );
