import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/settle_up.dart';

/// The simplified payment list (PLAN.md §4, DESIGN.md §11): your payments
/// on top, then the rest. Pay / Remind / Record arrive in step 7.
class SettleUpTab extends ConsumerWidget {
  const SettleUpTab({super.key, required this.groupId, required this.me});

  final String groupId;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nets = ref.watch(groupNetsProvider(groupId));
    final members = ref.watch(membersProvider(groupId)).valueOrNull ?? [];
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
        if (list.isEmpty) {
          return TabMessage(
            l10n.settleEveryoneSettled,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.extraColors.settled,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            if (list.mine.isNotEmpty)
              _Section(
                label: l10n.settleYoursLabel,
                rows: list.mine,
                meId: me.id,
                members: byId,
              ),
            if (list.others.isNotEmpty)
              _Section(
                label: l10n.settleOthersLabel,
                rows: list.others,
                meId: me.id,
                members: byId,
              ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.rows,
    required this.meId,
    required this.members,
  });

  final String label;
  final List<Transfer> rows;
  final String meId;
  final Map<String, Member> members;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionLabel(label),
      Panel(
        dividerIndent: avatarRowDividerIndent,
        children: [
          for (final t in rows)
            _TransferRow(transfer: t, meId: meId, members: members),
        ],
      ),
    ],
  );
}

/// "You pay Ali" (owe red) / "Ali pays you" (owed green) / "Bilal pays
/// Ali" (plain), with the amount at the end. Words carry the direction;
/// colour only backs them up (DESIGN.md §2).
class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.meId,
    required this.members,
  });

  final Transfer transfer;
  final String meId;
  final Map<String, Member> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    String name(String id) => members[id]?.displayName ?? '';
    final t = transfer;
    final youPay = t.from == meId;
    final paysYou = t.to == meId;
    // The avatar is the other person in your rows, the payer otherwise.
    final face = members[youPay ? t.to : t.from];
    final (text, color) = youPay
        ? (l10n.transferYouPay(name(t.to)), money.owe)
        : paysYou
        ? (l10n.transferPaysYou(name(t.from)), money.owed)
        : (l10n.transferPays(name(t.from), name(t.to)), null);

    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: MemberAvatar(
        name: face?.displayName ?? '',
        placeholder: face?.isPlaceholder ?? false,
      ),
      title: Text(text),
      trailing: Text(
        formatRupees(t.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
