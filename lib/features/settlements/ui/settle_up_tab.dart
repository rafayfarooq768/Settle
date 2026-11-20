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
/// top: pending ones to confirm or waiting, then the simplified payments
/// that involve you, each with its action. Then everyone else's.
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
        final mine = [
          for (final s in pending.toConfirm)
            _ToConfirmRow(settlement: s, members: byId, actions: actions),
          for (final s in pending.waiting)
            _WaitingRow(settlement: s, members: byId, actions: actions),
          for (final t in list.mine)
            _TransferRow(
              transfer: t,
              meId: me.id,
              members: byId,
              actions: actions,
              // One "I paid" at a time per person: wait, or cancel it.
              waiting: pending.waiting.any((s) => s.to == t.to),
            ),
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

/// A settle-up row: avatar, money line, amount, and the row's actions
/// under the text.
class _Row extends StatelessWidget {
  const _Row({
    required this.face,
    required this.title,
    required this.amount,
    this.amountColor,
    this.subtitle,
    this.actions = const [],
  });

  final Member? face;
  final String title;
  final int amount;
  final Color? amountColor;
  final String? subtitle;
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
          subtitle: subtitle == null ? null : Text(subtitle!),
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
              start: avatarRowDividerIndent,
              end: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Wrap(spacing: AppSpacing.sm, children: actions),
          ),
      ],
    );
  }
}

/// "You pay Ali" [I paid] / "Ali pays you" [Record payment] [Remind] /
/// "Bilal pays Ali" (no action). Words carry the direction; colour only
/// backs them up (DESIGN.md §2).
class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.meId,
    required this.members,
    this.actions,
    this.waiting = false,
  });

  final Transfer transfer;
  final bool waiting;
  final String meId;
  final Map<String, Member> members;

  /// Null for other people's rows.
  final SettleActions? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final money = context.moneyColors;
    final t = transfer;
    final from = members[t.from];
    final to = members[t.to];
    final act = actions;
    if (t.from == meId) {
      return _Row(
        face: to,
        title: l10n.transferYouPay(to?.displayName ?? ''),
        amount: t.amount,
        amountColor: money.owe,
        actions: [
          if (act != null && to != null && !waiting)
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
        actions: [
          if (act != null && from != null) ...[
            RowButton(
              label: l10n.recordPaymentButton,
              onPressed: () => act.record(from: from, owed: t.amount),
            ),
            RowButton(
              label: l10n.remindButton,
              kind: RowButtonKind.outlined,
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

/// Someone said "I paid" you: Confirm (counts it) or Not received.
class _ToConfirmRow extends StatelessWidget {
  const _ToConfirmRow({
    required this.settlement,
    required this.members,
    required this.actions,
  });

  final Settlement settlement;
  final Map<String, Member> members;
  final SettleActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final from = members[settlement.from];
    final name = from?.displayName ?? '';
    return _Row(
      face: from,
      title: l10n.pendingSaysPaidYou(name),
      amount: settlement.amount,
      amountColor: context.moneyColors.owed,
      actions: [
        RowButton(
          label: l10n.confirmButton,
          onPressed: () => actions.confirm(settlement),
        ),
        RowButton(
          label: l10n.notReceivedButton,
          kind: RowButtonKind.text,
          onPressed: () =>
              actions.remove(settlement, done: l10n.paymentNotReceived),
        ),
      ],
    );
  }
}

/// You said "I paid": muted until they confirm (DESIGN.md §6 Status).
class _WaitingRow extends StatelessWidget {
  const _WaitingRow({
    required this.settlement,
    required this.members,
    required this.actions,
  });

  final Settlement settlement;
  final Map<String, Member> members;
  final SettleActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final to = members[settlement.to];
    final name = to?.displayName ?? '';
    return _Row(
      face: to,
      title: l10n.pendingYouPaid(name),
      subtitle: l10n.pendingWaitingFor(name),
      amount: settlement.amount,
      amountColor: Theme.of(context).colorScheme.onSurfaceVariant,
      actions: [
        RowButton(
          label: l10n.cancelPaymentButton,
          kind: RowButtonKind.text,
          onPressed: () =>
              actions.remove(settlement, done: l10n.paymentCancelled),
        ),
      ],
    );
  }
}
