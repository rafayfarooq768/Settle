import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/text_input_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../domain/group.dart';
import 'edit_group_sheet.dart';
import 'group_actions.dart';
import 'groups_providers.dart';

/// Group settings (PLAN.md §8 screen 9): name/type, members, placeholders,
/// join code, leave.
class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final group = ref.watch(groupProvider(groupId)).valueOrNull;
    final me = ref.watch(myMemberProvider(groupId)).valueOrNull;
    final members = ref.watch(membersProvider(groupId)).valueOrNull ?? [];
    // Kept warm so Leave can check the balance instantly.
    ref.watch(groupNetsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
      body: SafeArea(
        child: group == null || me == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  SectionLabel(l10n.sectionGroup),
                  ListTile(
                    minTileHeight: AppSpacing.rowHeight,
                    title: Text(group.name),
                    subtitle: group.type.isEmpty ? null : Text(group.type),
                    onTap: () => _edit(context, ref, group, me.id),
                  ),
                  SectionLabel(
                    l10n.sectionMembers(members.where((m) => m.active).length),
                  ),
                  for (final m in members)
                    _MemberRow(
                      member: m,
                      isMe: m.id == me.id,
                      onTap: m.isPlaceholder
                          ? () => _rename(context, ref, m, me.id)
                          : null,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    child: OutlinedButton(
                      onPressed: () => addPlaceholderFlow(
                        context,
                        ref,
                        groupId: groupId,
                        actorMemberId: me.id,
                      ),
                      child: Text(l10n.addByNameButton),
                    ),
                  ),
                  SectionLabel(l10n.sectionInvite),
                  ListTile(
                    minTileHeight: AppSpacing.rowHeight,
                    leading: const Icon(Icons.qr_code_2_outlined),
                    title: Text(l10n.joinCodeRow(group.joinCode)),
                    onTap: () => context.push('/groups/$groupId/invite'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: context.moneyColors.owe,
                      ),
                      onPressed: () => _leave(context, ref, group, me),
                      child: Text(l10n.leaveGroupButton),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Group group,
    String myMemberId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showEditGroupSheet(context, group);
    if (result == null) return;
    try {
      await ref
          .read(groupRepositoryProvider)
          .updateGroup(
            group: group,
            actorMemberId: myMemberId,
            name: result.name,
            type: result.type,
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(l10n, e))));
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Member member,
    String myMemberId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final name = await showTextInputSheet(
      context,
      title: l10n.renamePlaceholderTitle,
      label: l10n.memberNameLabel,
      action: l10n.saveButton,
      initial: member.displayName,
      emptyError: l10n.errorNameRequired,
    );
    if (name == null || name == member.displayName) return;
    try {
      await ref
          .read(groupRepositoryProvider)
          .renamePlaceholder(
            groupId: groupId,
            actorMemberId: myMemberId,
            member: member,
            name: name,
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(l10n, e))));
    }
  }

  /// PLAN.md §6: only with a zero balance. Confirmed by dialog (DESIGN.md §8).
  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    Group group,
    Member me,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nets = ref.read(groupNetsProvider(groupId));
    if (!nets.hasValue) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
      return;
    }
    final myNet = nets.requireValue[me.id] ?? 0;
    if (myNet != 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.leaveGroupNotSettled(formatSignedRupees(myNet))),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveGroupDialogTitle(group.name)),
        content: Text(l10n.leaveGroupDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.moneyColors.owe,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.leaveGroupConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final uid = me.uid!;
    context.go('/home');
    try {
      await ref
          .read(groupRepositoryProvider)
          .leave(groupId: groupId, member: me, uid: uid);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(l10n, e))));
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isMe, this.onTap});

  final Member member;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = !member.active
        ? l10n.memberLeft
        : member.isPlaceholder
        ? l10n.memberNotJoined
        : null;
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: MemberAvatar(
        name: member.displayName,
        placeholder: member.isPlaceholder,
      ),
      title: Text(
        isMe ? l10n.memberYou(member.displayName) : member.displayName,
      ),
      subtitle: status == null ? null : Text(status),
      onTap: onTap,
    );
  }
}
