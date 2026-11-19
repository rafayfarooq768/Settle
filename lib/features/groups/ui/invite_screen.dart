import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_links.dart';
import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/panel.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/group.dart';
import 'groups_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/selectable_code.dart';

/// Invite (PLAN.md §6): the join code, its QR, and a WhatsApp share.
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final group = ref.watch(groupProvider(groupId)).valueOrNull;
    final me = ref.watch(myMemberProvider(groupId)).valueOrNull;
    final isCreator = group != null && me != null && group.createdBy == me.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteTitle)),
      body: group == null
          ? const Center(child: CircularProgressIndicator())
          : ScreenLayout(
              padded: false,
              body: [
                const SizedBox(height: AppSpacing.lg),
                _Padded(
                  Text(
                    l10n.inviteInstructions,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Panel(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          // Codes are Latin letters and digits; keep them
                          // LTR in Urdu.
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableCode(
                              group.joinCode,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _JoinQr(code: group.joinCode),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              actions: [
                LoadingButton(
                  label: l10n.shareOnWhatsApp,
                  onPressed: () => _share(context, group),
                ),
                const SizedBox(height: AppSpacing.sm),
                LoadingButton(
                  label: l10n.copyCodeButton,
                  onPressed: () => _copy(context, group.joinCode),
                  style: LoadingButtonStyle.outlined,
                ),
                if (isCreator) ...[
                  const SizedBox(height: AppSpacing.lg),
                  LoadingButton(
                    label: l10n.newCodeButton,
                    onPressed: () => _newCode(context, ref, group, me.id),
                    style: LoadingButtonStyle.text,
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _share(BuildContext context, Group group) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final text = l10n.inviteMessage(group.joinCode, AppLinks.download);
    final opened = await launchUrl(
      AppLinks.whatsAppShare(text),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorOpenWhatsApp)));
    }
  }

  Future<void> _copy(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
  }

  /// Irreversible, so it's confirmed (DESIGN.md §8).
  Future<void> _newCode(
    BuildContext context,
    WidgetRef ref,
    Group group,
    String myMemberId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newCodeDialogTitle),
        content: Text(l10n.newCodeDialogBody(group.joinCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.newCodeConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(groupRepositoryProvider)
          .regenerateJoinCode(group: group, actorMemberId: myMemberId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(l10n, e))));
    }
  }
}

/// Dark-on-light in both themes so any scanner reads it.
class _JoinQr extends StatelessWidget {
  const _JoinQr({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.extraColors;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.inviteQrLabel(code),
      child: QrImageView(
        data: code,
        size: AppSizes.qrCode,
        backgroundColor: colors.qrLight,
        padding: const EdgeInsets.all(AppSpacing.md),
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: colors.qrDark),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: colors.qrDark,
        ),
      ),
    );
  }
}

/// Screen-margin padding for content outside panels.
class _Padded extends StatelessWidget {
  const _Padded(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenHorizontal,
    ),
    child: child,
  );
}
