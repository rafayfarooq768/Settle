import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Plain muted "or" between the Google button and the email form. Text only,
/// no divider lines (DESIGN.md §12: no decorative separators).
class OrLabel extends StatelessWidget {
  const OrLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      AppLocalizations.of(context)!.orDivider,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class NameField extends StatelessWidget {
  const NameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      decoration: InputDecoration(
        labelText: l10n.signUpNameLabel,
        helperText: l10n.signUpNameHelper,
      ),
      validator: (value) {
        if ((value?.trim() ?? '').isEmpty) return l10n.errorNameRequired;
        return null;
      },
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(labelText: l10n.signInEmailLabel),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (!email.contains('@') || !email.contains('.')) {
          return l10n.errorInvalidEmail;
        }
        return null;
      },
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.isNewPassword,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isNewPassword;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      autofillHints: [
        isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(labelText: l10n.signInPasswordLabel),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.errorPasswordRequired;
        if (isNewPassword && value.length < 6) return l10n.errorWeakPassword;
        return null;
      },
    );
  }
}
