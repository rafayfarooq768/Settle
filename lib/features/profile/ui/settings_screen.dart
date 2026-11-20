import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/settle_logo.dart';
import '../../../core/widgets/text_input_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/ui/auth_providers.dart';
import '../../groups/ui/groups_providers.dart';
import 'profile_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Settings (PLAN.md §8 screen 11, DESIGN.md §11). Payment methods arrive in
/// step 10, language in step 12.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final me = ref.watch(myIdentityProvider);
    final user = ref.watch(userChangesProvider).valueOrNull;
    final auth = ref.read(authRepositoryProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ScreenLayout(
        padded: false,
        body: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SettleLogo(
                size: AppSizes.settingsLogo,
                variant: isDark
                    ? SettleLogoVariant.night
                    : SettleLogoVariant.light,
              ),
            ),
          ),
          SectionLabel(l10n.accountSection),
          Panel(
            dividerIndent: iconRowDividerIndent,
            children: [
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.nameRow),
                subtitle: Text(me?.name ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changeName(context, ref, me?.name ?? ''),
              ),
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                leading: const Icon(Icons.phone_outlined),
                title: Text(l10n.phoneLabel),
                subtitle: Text(
                  me == null || me.phone.isEmpty
                      ? l10n.phoneNotAdded
                      : formatPhone(me.phone),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePhone(context, ref, me?.phone ?? ''),
              ),
              // Read-only: no chevron, nothing to tap.
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                leading: const Icon(Icons.mail_outline),
                title: Text(l10n.emailRow),
                subtitle: Text(user?.email ?? ''),
              ),
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.passwordRow),
                subtitle: Text(
                  auth.hasPassword
                      ? l10n.changePasswordTitle
                      : l10n.googleOnlyAccount,
                ),
                trailing: auth.hasPassword
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: auth.hasPassword
                    ? () => context.push('/settings/password')
                    : null,
              ),
            ],
          ),
        ],
        actions: [
          LoadingButton(
            label: l10n.signOutButton,
            onPressed: () => auth.signOut(),
            style: LoadingButtonStyle.outlined,
          ),
        ],
      ),
    );
  }

  /// Saves the phone (or removes it when emptied) on the profile and your
  /// member doc in every group, for WhatsApp reminders.
  Future<void> _changePhone(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final typed = await showTextInputSheet(
      context,
      title: l10n.phoneTitle,
      label: l10n.phoneLabel,
      helper: l10n.phoneHelper,
      action: l10n.saveButton,
      initial: current.isEmpty ? '' : formatPhone(current),
      keyboardType: TextInputType.phone,
      validate: (text) =>
          normalizePhone(text) == null ? l10n.errorInvalidPhone : null,
    );
    final uid = ref.read(myIdentityProvider)?.uid;
    if (typed == null || uid == null) return;
    final phone = normalizePhone(typed) ?? '';
    if (phone == current) return;
    try {
      await ref.read(userRepositoryProvider).update(uid: uid, phone: phone);
      await ref
          .read(groupRepositoryProvider)
          .syncMyProfile(uid: uid, phone: phone);
      messenger.showMessage(
        phone.isEmpty ? l10n.phoneRemoved : l10n.phoneUpdated,
      );
    } catch (e) {
      messenger.showMessage(errorText(l10n, e));
    }
  }

  /// Updates the sign-in name, the profile doc, and your member doc in every
  /// group, so friends see the new name.
  Future<void> _changeName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final name = await showTextInputSheet(
      context,
      title: l10n.changeNameTitle,
      label: l10n.signUpNameLabel,
      helper: l10n.signUpNameHelper,
      action: l10n.saveButton,
      initial: current,
      emptyError: l10n.errorNameRequired,
    );
    final uid = ref.read(myIdentityProvider)?.uid;
    if (name == null || name == current || uid == null) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .update(uid: uid, displayName: name);
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      await ref
          .read(groupRepositoryProvider)
          .syncMyProfile(uid: uid, displayName: name);
      messenger.showMessage(l10n.nameUpdated);
    } catch (e) {
      messenger.showMessage(errorText(l10n, e));
    }
  }
}
