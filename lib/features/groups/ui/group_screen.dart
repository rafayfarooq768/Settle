import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../domain/group.dart';
import 'claim_member_view.dart';
import 'group_actions.dart';
import 'groups_providers.dart';
import '../../../core/widgets/loading_button.dart';

/// Group (DESIGN.md §11): header with your balance and the members, then
/// Expenses | Balances | Settle up. Until the user picks "Which one are
/// you?", that choice is shown instead, so a half-finished join resumes.
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final group = ref.watch(groupProvider(groupId));
    final me = ref.watch(myMemberProvider(groupId));
    final loaded = group.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.name ?? ''),
        actions: [
          if (loaded != null && me.valueOrNull != null)
            IconButton(
              tooltip: l10n.groupSettingsTooltip,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/groups/$groupId/settings'),
            ),
        ],
      ),
      body: SafeArea(
        child: switch ((group, me)) {
          (AsyncError(:final error), _) ||
          (_, AsyncError(:final error)) => _Centered(errorText(l10n, error)),
          (AsyncData(value: final Group g), AsyncData(value: null)) =>
            ClaimMemberView(group: g),
          (AsyncData(value: final Group g), AsyncData(value: final m?)) =>
            _GroupTabs(group: g, me: m),
          (AsyncData(value: null), _) => _Centered(l10n.errorGeneric),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.group, required this.me});

  final Group group;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _Header(group: group),
          const SizedBox(height: AppSpacing.sm),
          TabBar(
            tabs: [
              Tab(text: l10n.tabExpenses),
              Tab(text: l10n.tabBalances),
              Tab(text: l10n.tabSettleUp),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ExpensesTab(group: group, me: me),
                _BalancesTab(group: group, me: me),
                _SettleUpTab(group: group, me: me),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final net = ref.watch(myGroupNetProvider(group.id)).valueOrNull ?? 0;
    final members = (ref.watch(membersProvider(group.id)).valueOrNull ?? [])
        .where((m) => m.active)
        .toList();
    return Panel(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BalanceHeadline(net: net, settled: l10n.balanceSettledHere),
        ),
        const Divider(height: 1),
        ListTile(
          minTileHeight: AppSpacing.rowHeight,
          title: Text(
            l10n.membersCount(members.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: AvatarRow(
            names: [
              for (final m in members)
                (name: m.displayName, placeholder: m.isPlaceholder),
            ],
          ),
          onTap: () => context.push('/groups/${group.id}/settings'),
        ),
      ],
    );
  }
}

/// Expenses arrive in step 5. Until then: the empty state, and the next
/// useful step if you're alone in the group.
class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.group, required this.me});

  final Group group;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(membersProvider(group.id)).valueOrNull ?? [];
    final onlyMe = members.where((m) => m.active).length <= 1;

    void invite() => context.push('/groups/${group.id}/invite');
    void addByName() => addPlaceholderFlow(
      context,
      ref,
      groupId: group.id,
      actorMemberId: me.id,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          onlyMe ? l10n.groupOnlyYou : l10n.groupNoExpenses,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (onlyMe) ...[
          LoadingButton(label: l10n.inviteFriendsButton, onPressed: invite),
          const SizedBox(height: AppSpacing.sm),
          LoadingButton(
            label: l10n.addByNameButton,
            onPressed: addByName,
            style: LoadingButtonStyle.outlined,
          ),
        ] else
          LoadingButton(
            label: l10n.inviteFriendsButton,
            onPressed: invite,
            style: LoadingButtonStyle.outlined,
          ),
      ],
    );
  }
}

/// Members with their net, largest owed → largest owes (DESIGN.md §11).
class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.group, required this.me});

  final Group group;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nets = ref.watch(groupNetsProvider(group.id));
    final members = ref.watch(membersProvider(group.id)).valueOrNull ?? [];
    return nets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Centered(errorText(l10n, e)),
      data: (nets) {
        final rows =
            members.where((m) => m.active || (nets[m.id] ?? 0) != 0).toList()
              ..sort((a, b) => (nets[b.id] ?? 0).compareTo(nets[a.id] ?? 0));
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            Panel(
              dividerIndent: avatarRowDividerIndent,
              children: [
                for (final m in rows)
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
                    trailing: BalanceText(
                      net: nets[m.id] ?? 0,
                      wording: BalanceWording.member,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The simplified payment list (PLAN.md §4). Pay / Remind / Record
/// actions arrive with the settle flow in step 7.
class _SettleUpTab extends ConsumerWidget {
  const _SettleUpTab({required this.group, required this.me});

  final Group group;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nets = ref.watch(groupNetsProvider(group.id));
    final members = ref.watch(membersProvider(group.id)).valueOrNull ?? [];
    final names = {for (final m in members) m.id: m.displayName};
    String nameOf(String id) => id == me.id ? l10n.youLabel : names[id] ?? '';

    return nets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Centered(errorText(l10n, e)),
      data: (nets) {
        final transfers = simplifyDebts(
          nets,
          order: [for (final m in members) m.id],
        );
        if (transfers.isEmpty) {
          return _Centered(
            l10n.settleEveryoneSettled,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.extraColors.settled,
            ),
          );
        }
        // Rows involving you first (DESIGN.md §11).
        final mineFirst = [
          ...transfers.where((t) => t.from == me.id || t.to == me.id),
          ...transfers.where((t) => t.from != me.id && t.to != me.id),
        ];
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            Panel(
              dividerIndent: AppSpacing.lg,
              children: [
                for (final t in mineFirst)
                  ListTile(
                    minTileHeight: AppSpacing.rowHeight,
                    title: Text(
                      l10n.transferPays(nameOf(t.from), nameOf(t.to)),
                    ),
                    trailing: Text(
                      formatRupees(t.amount),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text, {this.style});

  final String text;
  final TextStyle? style;

  /// Near the top, not floating mid-screen (DESIGN.md §12 item 15).
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
    children: [
      const SizedBox(height: AppSpacing.xl),
      Text(text, textAlign: TextAlign.center, style: style),
    ],
  );
}
