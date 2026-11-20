import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/tab_message.dart';
import '../../balances/ui/balances_tab.dart';
import '../../settlements/domain/settle_up.dart';
import '../../settlements/ui/settle_up_tab.dart';
import '../../settlements/ui/settlements_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../domain/group.dart';
import 'claim_member_view.dart';
import 'group_actions.dart';
import 'groups_providers.dart';
import '../../../core/widgets/empty_state.dart';
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
          if (loaded != null && me.valueOrNull != null) ...[
            // Search and filter expenses (PLAN.md §3 item 7).
            IconButton(
              tooltip: l10n.searchTooltip,
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/groups/$groupId/search'),
            ),
            // Who did what (PLAN.md §3 item 12).
            IconButton(
              tooltip: l10n.activityTooltip,
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/groups/$groupId/activity'),
            ),
            IconButton(
              tooltip: l10n.groupSettingsTooltip,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/groups/$groupId/settings'),
            ),
          ],
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
          const SizedBox(height: AppSpacing.lg),
          _Header(group: group),
          const SizedBox(height: AppSpacing.sm),
          TabBar(
            tabs: [
              Tab(text: l10n.tabExpenses),
              Tab(text: l10n.tabBalances),
              _SettleUpTabLabel(groupId: group.id, meId: me.id),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ExpensesTab(group: group, me: me),
                BalancesTab(groupId: group.id, me: me),
                SettleUpTab(group: group, me: me),
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
    final muted = theme.colorScheme.onSurfaceVariant;
    final net = ref.watch(myGroupNetProvider(group.id)).valueOrNull ?? 0;
    final members = (ref.watch(membersProvider(group.id)).valueOrNull ?? [])
        .where((m) => m.active)
        .toList();
    // No panel: the balance is the screen's headline, straight on the
    // background, aligned with the list text below.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _headerInset),
          child: BalanceHero(net: net),
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: () => context.push('/groups/${group.id}/settings'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _headerInset),
              child: Row(
                children: [
                  AvatarRow(
                    ring: theme.scaffoldBackgroundColor,
                    names: [
                      for (final m in members)
                        (name: m.displayName, placeholder: m.isPlaceholder),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.membersCount(members.length),
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  Icon(Icons.chevron_right, color: muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lines the header up with the text inside the panels below.
const _headerInset = AppSpacing.screenHorizontal + AppSpacing.lg;

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
          ? ExpenseList(
              expenses: list,
              settlements:
                  ref.watch(settlementsProvider(group.id)).valueOrNull ??
                  const [],
              members: all,
              meId: me.id,
              onOpen: (e) =>
                  context.push('/groups/${group.id}/expenses/${e.id}'),
            )
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

    // The FAB already adds expenses, so these are the other next steps.
    return EmptyState(
      title: onlyMe ? l10n.groupOnlyYou : l10n.groupNoExpenses,
      actions: onlyMe
          ? [
              LoadingButton(label: l10n.inviteFriendsButton, onPressed: invite),
              LoadingButton(
                label: l10n.addByNameButton,
                onPressed: addByName,
                style: LoadingButtonStyle.outlined,
              ),
            ]
          : [
              LoadingButton(
                label: l10n.inviteFriendsButton,
                onPressed: invite,
                style: LoadingButtonStyle.outlined,
              ),
            ],
    );
  }
}

/// "Settle up", with a count when payments wait for your confirmation:
/// the one actionable badge (DESIGN.md §6 Status indicators).
class _SettleUpTabLabel extends ConsumerWidget {
  const _SettleUpTabLabel({required this.groupId, required this.meId});

  final String groupId;
  final String meId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settlements = ref.watch(settlementsProvider(groupId)).valueOrNull;
    final count = pendingForMe(settlements ?? const [], meId).toConfirm.length;
    return Tab(
      child: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: Text(l10n.tabSettleUp),
      ),
    );
  }
}
