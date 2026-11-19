import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/ui/auth_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';

/// Home (DESIGN.md §11): greeting and the group list. The overall balance,
/// per-group balances and the Add expense FAB arrive in steps 5 and 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userChangesProvider).valueOrNull;
    final displayName = user?.displayName?.trim() ?? '';
    final name = displayName.isNotEmpty ? displayName : (user?.email ?? '');
    final groups = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeGreeting(name)),
        actions: [
          PopupMenuButton<void>(
            tooltip: l10n.moreOptions,
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => ref.read(authRepositoryProvider).signOut(),
                child: Text(l10n.signOutButton),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: groups.when(
          // Cached data shows at once; this only appears on a cold start.
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(errorText(l10n, e)),
          data: (groups) =>
              groups.isEmpty ? const _NoGroups() : _GroupList(groups: groups),
        ),
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...groups]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ListView(
      children: [
        for (final group in sorted)
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            title: Text(group.name),
            subtitle: group.type.isEmpty ? null : Text(group.type),
            onTap: () => context.push('/groups/${group.id}'),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () => context.push('/groups/new'),
                child: Text(l10n.createGroupButton),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.push('/join'),
                child: Text(l10n.joinWithCodeButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// DESIGN.md §9: plain text and the actions, no illustration.
class _NoGroups extends StatelessWidget {
  const _NoGroups();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.homeNoGroups,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => context.push('/groups/new'),
            child: Text(l10n.createGroupButton),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push('/join'),
            child: Text(l10n.joinWithCodeButton),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
