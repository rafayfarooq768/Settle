import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/ui/profile_providers.dart';
import '../domain/group.dart';
import 'groups_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// "Which one are you?" (PLAN.md §6): tap your placeholder to take over its
/// history, or "I'm not listed" to join as a new member.
class ClaimMemberView extends ConsumerStatefulWidget {
  const ClaimMemberView({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<ClaimMemberView> createState() => _ClaimMemberViewState();
}

class _ClaimMemberViewState extends ConsumerState<ClaimMemberView> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function(MyIdentity me) action) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final me = ref.read(myIdentityProvider);
    if (me == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(me);
      messenger.showMessage(l10n.joinedGroup(widget.group.name));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final repo = ref.read(groupRepositoryProvider);
    final groupId = widget.group.id;
    final uid = ref.watch(myIdentityProvider)?.uid;
    final members = ref.watch(membersProvider(groupId)).valueOrNull ?? [];
    final placeholders = members.where((m) => m.isPlaceholder && m.active);
    final previous = members.where((m) => m.uid == uid && !m.active);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.claimTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.claimBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final old in previous)
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            leading: MemberAvatar(name: old.displayName),
            title: Text(l10n.claimRejoin(old.displayName)),
            enabled: !_busy,
            onTap: () =>
                _run((_) => repo.rejoin(groupId: groupId, member: old)),
          ),
        for (final p in placeholders)
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            leading: MemberAvatar(name: p.displayName, placeholder: true),
            title: Text(p.displayName),
            enabled: !_busy,
            onTap: () => _run(
              (me) => repo.claimPlaceholder(
                groupId: groupId,
                placeholder: p,
                uid: me.uid,
                paymentMethods: me.paymentMethods,
                phone: me.phone,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                FormMessage(_error!),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                LoadingButton(
                  label: l10n.claimNotListed,
                  onPressed: () => _run(
                    (me) => repo
                        .joinAsNewMember(
                          groupId: groupId,
                          uid: me.uid,
                          displayName: me.name,
                          paymentMethods: me.paymentMethods,
                          phone: me.phone,
                        )
                        .then((_) {}),
                  ),
                  style: LoadingButtonStyle.outlined,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
