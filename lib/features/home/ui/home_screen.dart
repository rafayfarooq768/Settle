import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../settlements/domain/settle_up.dart';
import '../../settlements/ui/settlements_providers.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/add_row.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/row_chevron.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../../profile/ui/profile_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/app_sheet.dart';

/// Home (DESIGN.md §11): overall balance, then your groups with your balance
/// in each, and Add expense (FAB).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final me = ref.watch(myIdentityProvider);
    final groups = ref.watch(myGroupsProvider);
    final firstName = (me?.name ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeGreeting(firstName)),
        actions: [
          IconButton(
            tooltip: l10n.settingsTooltip,
            onPressed: () => context.push('/settings'),
            icon: MemberAvatar(name: me?.name ?? ''),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      // Add expense pinned at the bottom in the thumb zone, full width
      // (owner, 2026-11-20): Home is short, so a corner FAB left the
      // bottom of the screen looking empty.
      bottomNavigationBar: switch (groups.valueOrNull) {
        final list? when list.isNotEmpty => _BottomAction(
          child: LoadingButton(
            label: l10n.addExpenseButton,
            icon: Icons.add,
            onPressed: () => _addExpense(context, list),
          ),
        ),
        _ => null,
      },
      body: SafeArea(
        child: groups.when(
          // Cached data shows at once; this only appears on a cold start.
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Centered(errorText(l10n, e)),
          data: (groups) =>
              groups.isEmpty ? const _NoGroups() : _HomeBody(groups: groups),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...groups]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // Show Home once, complete: not a total that fills in group by group
    // with rows growing their balances one after another. Cached data is
    // ready at once; only a first start waits here.
    final ready = groups.every((g) {
      final net = ref.watch(myGroupNetProvider(g.id));
      return net.hasValue || net.hasError;
    });
    if (!ready) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        _OverallPanel(groups: sorted),
        SectionLabel(l10n.groupsLabel),
        Panel(
          dividerIndent: AppSpacing.lg,
          children: [
            for (final group in sorted) _GroupRow(group: group),
            AddRow(
              label: l10n.newGroupOrJoin,
              contentPadding: chevronRowPadding,
              onTap: () => _showNewOrJoin(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Overall balance across groups, from each group's computed nets.
class _OverallPanel extends ConsumerWidget {
  const _OverallPanel({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Unknown (null) if any group's balance is: a total missing a group
    // would be a wrong number, not a smaller one.
    int? owe = 0, owed = 0;
    for (final g in groups) {
      final net = ref.watch(myGroupNetProvider(g.id)).valueOrNull;
      if (net == null) {
        owe = owed = null;
        break;
      }
      if (net < 0) owe = owe! - net;
      if (net > 0) owed = owed! + net;
    }
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l10n.overallLabel),
        Panel(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceHero(
                    net: owe == null || owed == null ? null : owed - owe,
                    large: false,
                    settledText: l10n.balanceAllSettled,
                  ),
                  if (owe != null && owed != null && owe > 0 && owed > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.balanceBothLine(
                        formatRupees(owe),
                        formatRupees(owed),
                      ),
                      style: muted,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(membersProvider(group.id)).valueOrNull;
    final net = ref.watch(myGroupNetProvider(group.id)).valueOrNull;
    final count = members?.where((m) => m.active).length;
    final countText = count == null ? null : l10n.membersCount(count);
    final subtitle = switch ((group.type.isEmpty, countText)) {
      (true, null) => null,
      (true, final c?) => c,
      (false, null) => group.type,
      (false, final c?) => l10n.groupSubtitle(group.type, c),
    };
    final theme = Theme.of(context);
    // In-app notice instead of push (PLAN.md §3): someone says they paid.
    final me = ref.watch(myMemberProvider(group.id)).valueOrNull;
    final settlements = ref.watch(settlementsProvider(group.id)).valueOrNull;
    final toConfirm = me == null
        ? 0
        : pendingForMe(settlements ?? const [], me.id).toConfirm.length;
    // No tile: the name is the strongest thing in the row, and the
    // chevron says the row opens the group.
    return ListTile(
      minTileHeight: AppSizes.groupRowHeight,
      contentPadding: chevronRowPadding,
      title: Text(group.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: toConfirm > 0
          ? Text(
              l10n.pendingToConfirm(toConfirm),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.extraColors.link,
              ),
            )
          : subtitle == null
          ? null
          : Text(subtitle),
      trailing: RowEnd(child: net == null ? null : BalanceStack(net: net)),
      onTap: () => context.push('/groups/${group.id}'),
    );
  }
}

/// With one group, go straight to Add expense; otherwise ask which group
/// in a sheet first (DESIGN.md §8).
void _addExpense(BuildContext context, List<Group> groups) {
  if (groups.length == 1) {
    context.push('/groups/${groups.single.id}/expenses/new');
    return;
  }
  final l10n = AppLocalizations.of(context)!;
  showAppSheet<void>(
    context: context,
    scrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            SheetTitle(l10n.pickGroupTitle),
            for (final g in groups)
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                title: Text(g.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheet).pop();
                  context.push('/groups/${g.id}/expenses/new');
                },
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    ),
  );
}

/// DESIGN.md §8: a bottom sheet for the small choice.
void _showNewOrJoin(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showAppSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            leading: const Icon(Icons.group_add_outlined),
            title: Text(l10n.createGroupButton),
            onTap: () {
              Navigator.of(sheet).pop();
              context.push('/groups/new');
            },
          ),
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            leading: const Icon(Icons.qr_code_2_outlined),
            title: Text(l10n.joinWithCodeButton),
            onTap: () {
              Navigator.of(sheet).pop();
              context.push('/join');
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    ),
  );
}

/// The bottom action bar: 16 at the sides, 8 above, 16 below.
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      child: child,
    ),
  );
}

/// No groups yet (DESIGN.md §9, owner 2026-11-20): what Settle does in
/// three real steps, then the two ways in, pinned at the bottom in the
/// thumb zone like the other forms. No illustration.
class _NoGroups extends StatelessWidget {
  const _NoGroups();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ScreenLayout(
      padded: false,
      body: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeNoGroupsTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeNoGroupsLine,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SectionLabel(l10n.homeHowItWorks),
        Panel(
          dividerIndent: iconRowDividerIndent,
          children: [
            _Step(number: 1, text: l10n.homeStep1),
            _Step(number: 2, text: l10n.homeStep2),
            _Step(number: 3, text: l10n.homeStep3),
          ],
        ),
      ],
      actions: [
        LoadingButton(
          label: l10n.createGroupButton,
          onPressed: () => context.push('/groups/new'),
        ),
        const SizedBox(height: AppSpacing.sm),
        LoadingButton(
          label: l10n.joinWithCodeButton,
          onPressed: () => context.push('/join'),
          style: LoadingButtonStyle.text,
        ),
      ],
    );
  }
}

/// One step: its number in brand teal (the steps really are a sequence),
/// then the sentence.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: SizedBox(
        width: AppSizes.icon,
        child: Text(
          '$number',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.extraColors.link,
          ),
        ),
      ),
      title: Text(text, style: theme.textTheme.bodyLarge),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
