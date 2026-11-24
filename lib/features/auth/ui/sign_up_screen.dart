import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/phone/phone_number.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/auth_repository.dart';
import 'auth_error_text.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';
import 'google_sign_in_button.dart';
import '../../profile/ui/profile_providers.dart';
import '../../../core/widgets/screen_layout.dart';

enum _Action { email, google }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  _Action? _running;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(_Action action, Future<void> Function() task) async {
    setState(() {
      _running = action;
      _errorMessage = null;
    });
    try {
      await task();
      // On success the router redirects to Home.
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = authFailureMessage(context, e.failure);
      setState(() => _errorMessage = message.isEmpty ? null : message);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  void _signUpWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    // Saved onto the profile once the account exists.
    ref.read(signUpPhoneProvider.notifier).state =
        normalizePhone(_phoneController.text) ?? '';
    _run(
      _Action.email,
      () => ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
    );
  }

  void _continueWithGoogle() {
    // Google sign-in creates the account on first use, with the Google name.
    _run(
      _Action.google,
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _running != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
      body: Form(
        key: _formKey,
        child: ScreenLayout(
          body: [
            const SizedBox(height: AppSpacing.lg),
            GoogleSignInButton(
              isLoading: _running == _Action.google,
              onPressed: busy ? null : _continueWithGoogle,
            ),
            const SizedBox(height: AppSpacing.lg),
            const OrLabel(),
            const SizedBox(height: AppSpacing.lg),
            NameField(controller: _nameController),
            const SizedBox(height: AppSpacing.lg),
            EmailField(controller: _emailController),
            const SizedBox(height: AppSpacing.lg),
            PhoneField(controller: _phoneController),
            const SizedBox(height: AppSpacing.lg),
            PasswordField(
              controller: _passwordController,
              isNewPassword: true,
              onSubmitted: busy ? null : _signUpWithEmail,
            ),
          ],
          actions: [
            if (_errorMessage != null) ...[
              FormMessage(_errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            LoadingButton(
              label: l10n.signUpButton,
              isLoading: _running == _Action.email,
              onPressed: busy ? null : _signUpWithEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap, so a large font size moves "Sign in" to its own line.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.signInPrompt,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                LoadingButton(
                  label: l10n.signInButton,
                  onPressed: busy ? null : () => context.pop(),
                  style: LoadingButtonStyle.text,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
