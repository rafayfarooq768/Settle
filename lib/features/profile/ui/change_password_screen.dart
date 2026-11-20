import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/ui/auth_error_text.dart';
import '../../auth/ui/auth_providers.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Change password: current password first (Firebase needs a recent
/// sign-in), then the new one. Needs a connection.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _currentError;
  String? _nextError;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _currentError = _current.text.isEmpty ? l10n.errorPasswordRequired : null;
      _nextError = _next.text.length < 6 ? l10n.errorWeakPassword : null;
      _error = null;
    });
    if (_currentError != null || _nextError != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(current: _current.text, next: _next.text);
      messenger.showMessage(l10n.passwordChanged);
      if (mounted) context.pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.failure) {
          case AuthFailure.wrongPassword:
            _currentError = l10n.errorCurrentPasswordWrong;
          case AuthFailure.weakPassword:
            _nextError = l10n.errorWeakPassword;
          default:
            _error = authFailureMessage(context, e.failure);
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: ScreenLayout(
        body: [
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _current,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.currentPasswordLabel,
              errorText: _currentError,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _next,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.newPasswordLabel,
              errorText: _nextError,
            ),
          ),
        ],
        actions: [
          if (_error != null) ...[
            FormMessage(_error!),
            const SizedBox(height: AppSpacing.md),
          ],
          LoadingButton(
            label: l10n.saveButton,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
