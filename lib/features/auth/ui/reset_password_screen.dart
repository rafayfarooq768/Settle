import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/auth_repository.dart';
import 'auth_error_text.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';
import '../../../core/widgets/screen_layout.dart';

/// Two states: the email form, then "Check your email" once the link is sent.
/// The new password itself is chosen on the page the emailed link opens.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _sentTo;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sentTo == null && !_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) setState(() => _sentTo = email);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = authFailureMessage(context, e.failure));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: _sentTo == null ? _buildForm(l10n) : _buildSent(l10n),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: ScreenLayout(
        body: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.resetPasswordInstructions,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          EmailField(controller: _emailController),
        ],
        actions: [
          if (_errorMessage != null) ...[
            FormMessage(_errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          LoadingButton(
            label: l10n.resetPasswordButton,
            isLoading: _isLoading,
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildSent(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return ScreenLayout(
      body: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.resetPasswordCheckEmailTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.resetPasswordCheckEmailBody(_sentTo!),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.resetPasswordSpamHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      actions: [
        if (_errorMessage != null) ...[
          FormMessage(_errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        LoadingButton(label: l10n.backToSignIn, onPressed: () => context.pop()),
        const SizedBox(height: AppSpacing.sm),
        LoadingButton(
          label: l10n.resetPasswordResend,
          onPressed: _isLoading ? null : _send,
          style: LoadingButtonStyle.text,
        ),
      ],
    );
  }
}
