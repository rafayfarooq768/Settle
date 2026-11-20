import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/text_input_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/ui/balances_providers.dart';
import '../domain/group.dart';
import 'edit_group_sheet.dart';
import 'group_actions.dart';
import 'groups_providers.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Group settings (PLAN.md §8 screen 9, DESIGN.md §11): name/type, members,
/// placeholders, join code, leave.
class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final group = ref.watch(groupProvider(groupId)).valueOrNull;
    final me = ref.watch(myMemberProvider(groupId)).valueOrNull;
    final members = (ref.watch(membersProvider(groupId)).valueOrNull ?? [])
        .where((m) => m.active)
        .toList();
    // Kept warm so Leave and Remove can check balances instantly.
    ref.watch(groupNetsProvider(groupId));

    if (group == null || me == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final actions = _SettingsActions(context, ref, groupId, me);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
      body: ScreenLayout(
        padded: false,
        body: [
          SectionLabel(l10n.sectionGroup),
          Panel(
            children: [
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                title: Text(group.name),
                subtitle: group.type.isEmpty ? null : Text(group.type),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => actions.editGroup(group),
              ),
            ],
          ),
          SectionLabel(l10n.sectionMembers(members.length)),
          Panel(
            dividerIndent: avatarRowDividerIndent,
            children: [
              for (final m in members)
                _MemberRow(
                  member: m,
                  isMe: m.id == me.id,
                  onTap: m.isPlaceholder
                      ? () => actions.placeholderMenu(m)
                      : null,
                ),
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                leading: const SizedBox.square(
                  dimension: AppSizes.avatar,
                  child: Icon(Icons.person_add_alt_outlined),
                ),
                title: Text(l10n.addByNameButton),
                onTap: () => addPlaceholderFlow(
                  context,
                  ref,
                  groupId: groupId,
                  actorMemberId: me.id,
                ),
              ),
            ],
          ),
          SectionLabel(l10n.sectionInvite),
          Panel(
            children: [
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                leading: const SizedBox.square(
                  dimension: AppSizes.avatar,
                  child: Icon(Icons.qr_code_2_outlined),
                ),
                title: Text(l10n.joinCodeRow(group.joinCode)),
                onTap: () => context.push('/groups/$groupId/invite'),
              ),
            ],
          ),
        ],
        actions: [
          // The last real member deletes instead of leaving, so no group is
          // left with nobody in it (PLAN.md §6).
          if (group.memberUids.length <= 1)
            LoadingButton(
              label: l10n.deleteGroupButton,
              style: LoadingButtonStyle.text,
              foregroundColor: context.moneyColors.owe,
              onPressed: () => actions.delete(group),
            )
          else
            LoadingButton(
              label: l10n.leaveGroupButton,
              style: LoadingButtonStyle.text,
              foregroundColor: context.moneyColors.owe,
              onPressed: () => actions.leave(group),
            ),
        ],
      ),
    );
  }
}

/// The screen's actions, kept out of build() so it stays short.
class _SettingsActions {
  _SettingsActions(this.context, this.ref, this.groupId, this.me);

  final BuildContext context;
  final WidgetRef ref;
  final String groupId;
  final Member me;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  void _showError(ScaffoldMessengerState messenger, Object e) =>
      messenger.showMessage(errorText(l10n, e));

  /// null while balances are still loading.
  int? _netOf(String memberId) {
    final nets = ref.read(groupNetsProvider(groupId));
    return nets.hasValue ? nets.requireValue[memberId] ?? 0 : null;
  }

  Future<void> editGroup(Group group) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showEditGroupSheet(context, group);
    if (result == null) return;
    try {
      await ref
          .read(groupRepositoryProvider)
          .updateGroup(
            group: group,
            actorMemberId: me.id,
            name: result.name,
            type: result.type,
          );
    } catch (e) {
      _showError(messenger, e);
    }
  }

  /// DESIGN.md §11: Change name / Remove, in a sheet.
  Future<void> placeholderMenu(Member placeholder) async {
    final remove = await showAppSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: AppSpacing.rowHeight,
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.renamePlaceholderTitle),
              onTap: () => Navigator.of(sheet).pop(false),
            ),
            ListTile(
              minTileHeight: AppSpacing.rowHeight,
              iconColor: sheet.moneyColors.owe,
              textColor: sheet.moneyColors.owe,
              leading: const Icon(Icons.person_remove_outlined),
              title: Text(l10n.placeholderRemove),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
    if (remove == null || !context.mounted) return;
    remove ? await _remove(placeholder) : await _rename(placeholder);
  }

  Future<void> _rename(Member member) async {
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
            actorMemberId: me.id,
            member: member,
            name: name,
          );
    } catch (e) {
      _showError(messenger, e);
    }
  }

  /// Only at a zero balance (PLAN.md §6); hidden, not deleted, so no
  /// confirmation dialog is needed.
  Future<void> _remove(Member placeholder) async {
    final messenger = ScaffoldMessenger.of(context);
    final net = _netOf(placeholder.id);
    if (net == null) {
      messenger.showMessage(l10n.errorNetwork);
      return;
    }
    if (net != 0) {
      messenger.showMessage(
        l10n.placeholderNotSettled(
          placeholder.displayName,
          formatSignedRupees(net),
        ),
      );
      return;
    }
    try {
      await ref
          .read(groupRepositoryProvider)
          .removePlaceholder(
            groupId: groupId,
            actorMemberId: me.id,
            placeholder: placeholder,
          );
      messenger.showMessage(l10n.placeholderRemoved(placeholder.displayName));
    } catch (e) {
      _showError(messenger, e);
    }
  }

  /// Irreversible, so confirmed by dialog (DESIGN.md §8). Needs a
  /// connection; stays on the screen with an error if it fails.
  Future<void> delete(Group group) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.deleteGroupDialogTitle(group.name)),
        content: Text(l10n.deleteGroupDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: dialog.moneyColors.owe,
            ),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.deleteGroupConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = l10n.groupDeleted(group.name);
    final router = GoRouter.of(context);
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(group);
      router.go('/home');
      messenger.showMessage(deleted);
    } catch (e) {
      _showError(messenger, e);
    }
  }

  /// PLAN.md §6: only with a zero balance. Confirmed by dialog (DESIGN.md §8).
  Future<void> leave(Group group) async {
    final messenger = ScaffoldMessenger.of(context);
    final myNet = _netOf(me.id);
    if (myNet == null) {
      messenger.showMessage(l10n.errorNetwork);
      return;
    }
    if (myNet != 0) {
      messenger.showMessage(
        l10n.leaveGroupNotSettled(formatSignedRupees(myNet)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.leaveGroupDialogTitle(group.name)),
        content: Text(l10n.leaveGroupDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: dialog.moneyColors.owe,
            ),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.leaveGroupConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(groupRepositoryProvider);
    context.go('/home');
    try {
      await repo.leave(groupId: groupId, member: me, uid: me.uid!);
    } catch (e) {
      _showError(messenger, e);
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
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: MemberAvatar(
        name: member.displayName,
        placeholder: member.isPlaceholder,
      ),
      title: Text(
        isMe ? l10n.memberYou(member.displayName) : member.displayName,
      ),
      subtitle: member.isPlaceholder ? Text(l10n.memberNotJoined) : null,
      trailing: onTap == null ? null : const Icon(Icons.more_horiz),
      onTap: onTap,
    );
  }
}
