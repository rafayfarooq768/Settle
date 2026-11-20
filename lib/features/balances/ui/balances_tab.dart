import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
        ],
      ),
    );
  }
}
