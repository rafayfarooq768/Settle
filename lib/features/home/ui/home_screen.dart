import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../../profile/ui/profile_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/app_sheet.dart';

/// Home (DESIGN.md §11): overall balance, then your groups with your balance
/// in each. Add expense (FAB) arrives in step 5.
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
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        _OverallPanel(groups: sorted),
        SectionLabel(l10n.groupsLabel),
        Panel(
          dividerIndent: avatarRowDividerIndent,
          children: [
            for (final group in sorted) _GroupRow(group: group),
            ListTile(
              minTileHeight: AppSpacing.rowHeight,
              leading: const SizedBox.square(
                dimension: AppSizes.avatar,
                child: Icon(Icons.add),
              ),
              title: Text(l10n.newGroupOrJoin),
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
    var owe = 0, owed = 0;
    for (final g in groups) {
      final net = ref.watch(myGroupNetProvider(g.id)).valueOrNull ?? 0;
      if (net < 0) owe -= net;
      if (net > 0) owed += net;
    }
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Panel(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.overallLabel, style: muted),
              const SizedBox(height: AppSpacing.xs),
              BalanceHeadline(net: owed - owe, settled: l10n.balanceAllSettled),
              if (owe > 0 && owed > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.balanceBothLine(formatRupees(owe), formatRupees(owed)),
                  style: muted,
                ),
              ],
            ],
          ),
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
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: MemberAvatar.group(name: group.name),
      title: Text(group.name),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: net == null ? null : BalanceText(net: net),
      onTap: () => context.push('/groups/${group.id}'),
    );
  }
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

/// DESIGN.md §9: plain text and the actions, no illustration.
class _NoGroups extends StatelessWidget {
  const _NoGroups();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Panel(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.homeNoGroups,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
              ),
            ),
          ],
        ),
      ],
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
