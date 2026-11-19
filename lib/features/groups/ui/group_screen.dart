import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/group.dart';
import 'claim_member_view.dart';
import 'group_actions.dart';
import 'groups_providers.dart';

/// Group (DESIGN.md §11). Tabs (Expenses | Balances | Settle up) arrive with
/// expenses in step 5. Until the user picks "Which one are you?", that
/// choice is shown here instead, so a half-finished join can be resumed.
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
            _GroupBody(group: g, myMemberId: m.id),
          (AsyncData(value: null), _) => _Centered(l10n.errorGeneric),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _GroupBody extends ConsumerWidget {
  const _GroupBody({required this.group, required this.myMemberId});

  final Group group;
  final String myMemberId;

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
      actorMemberId: myMemberId,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            onlyMe ? l10n.groupOnlyYou : l10n.groupNoExpenses,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (onlyMe) ...[
            FilledButton(
              onPressed: invite,
              child: Text(l10n.inviteFriendsButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: addByName,
              child: Text(l10n.addByNameButton),
            ),
          ] else
            OutlinedButton(
              onPressed: invite,
              child: Text(l10n.inviteFriendsButton),
            ),
        ],
      ),
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
