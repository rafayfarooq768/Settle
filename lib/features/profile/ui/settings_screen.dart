import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/add_row.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/panel_note.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/settle_logo.dart';
import '../../../core/widgets/text_input_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/ui/auth_providers.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/payment_method.dart';
import '../domain/payment_methods.dart';
import 'profile_providers.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Settings (PLAN.md §8 screen 11, DESIGN.md §11).
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
              // Google-only accounts have no password to change, so no
              // row at all (owner, 2026-11-20).
              if (auth.hasPassword)
                ListTile(
                  minTileHeight: AppSpacing.rowHeight,
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.passwordRow),
                  subtitle: Text(l10n.changePasswordTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/password'),
                ),
            ],
          ),
          SectionLabel(l10n.paymentMethodsSection),
          _PaymentMethodsPanel(methods: me?.paymentMethods ?? const []),
          PanelNote(l10n.paymentMethodsNote),
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
      await ref
          .read(groupRepositoryProvider)
          .saveMyProfile(uid: uid, phone: phone);
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
          .read(groupRepositoryProvider)
          .saveMyProfile(uid: uid, displayName: name);
      await ref.read(authRepositoryProvider).updateDisplayName(name);

      messenger.showMessage(l10n.nameUpdated);
    } catch (e) {
      messenger.showMessage(errorText(l10n, e));
    }
  }
}

/// Your payment methods in the order you added them: name over the
/// number, then a chevron. The last row adds one (up to the rules' 20).
class _PaymentMethodsPanel extends StatelessWidget {
  const _PaymentMethodsPanel({required this.methods});

  final List<PaymentMethod> methods;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Panel(
      dividerIndent: AppSpacing.lg,
      children: [
        for (final m in methods)
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              m.accountNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/payment-methods/${m.id}'),
          ),
        if (methods.length < maxPaymentMethods)
          AddRow(
            label: l10n.addPaymentMethod,
            onTap: () => context.push('/settings/payment-methods/new'),
          ),
      ],
    );
  }
}
