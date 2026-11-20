import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/tab_message.dart';
import '../../balances/ui/balances_tab.dart';
import '../../settlements/ui/settle_up_tab.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../domain/group.dart';
import 'claim_member_view.dart';
import 'group_actions.dart';
import 'groups_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../expenses/ui/expense_list.dart';
import '../../expenses/ui/expenses_providers.dart';

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
    final activeCount = (ref.watch(membersProvider(groupId)).valueOrNull ?? [])
        .where((m) => m.active)
        .length;

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
      // Only once you're a member (not while picking "Which one are you?")
      // and someone else is in the group to split with. Until then the
      // empty state's Invite is the screen's one primary action.
      floatingActionButton:
          loaded != null && me.valueOrNull != null && activeCount > 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/groups/$groupId/expenses/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.addExpenseButton),
            )
          : null,
      body: SafeArea(
        child: switch ((group, me)) {
          (AsyncError(:final error), _) ||
          (_, AsyncError(:final error)) => TabMessage(errorText(l10n, error)),
          (AsyncData(value: final Group g), AsyncData(value: null)) =>
            ClaimMemberView(group: g),
          (AsyncData(value: final Group g), AsyncData(value: final m?)) =>
            _GroupTabs(group: g, me: m),
          (AsyncData(value: null), _) => TabMessage(l10n.errorGeneric),
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
                BalancesTab(groupId: group.id, me: me),
                SettleUpTab(groupId: group.id, me: me),
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

/// The group's expenses by day; when there are none, the empty state with
/// the next useful step (DESIGN.md §9).
class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.group, required this.me});

  final Group group;
  final Member me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final all = ref.watch(membersProvider(group.id)).valueOrNull ?? [];
    final expenses = ref.watch(expensesProvider(group.id));
    return expenses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => TabMessage(errorText(l10n, e)),
      data: (list) => list.any((e) => !e.deleted)
          ? ExpenseList(expenses: list, members: all, meId: me.id)
          : _NoExpenses(group: group, me: me, members: all),
    );
  }
}

class _NoExpenses extends ConsumerWidget {
  const _NoExpenses({
    required this.group,
    required this.me,
    required this.members,
  });

  final Group group;
  final Member me;
  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
        // The FAB already adds expenses, so these are the other next steps.
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
