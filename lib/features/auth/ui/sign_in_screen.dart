import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/settle_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/auth_repository.dart';
import 'auth_error_text.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';
import 'google_sign_in_button.dart';
import '../../../core/widgets/screen_layout.dart';

enum _Action { email, google }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _Action? _running;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
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

  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    _run(
      _Action.email,
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
    );
  }

  void _signInWithGoogle() {
    _run(
      _Action.google,
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final busy = _running != null;
    final logoVariant = theme.brightness == Brightness.dark
        ? SettleLogoVariant.night
        : SettleLogoVariant.light;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: ScreenLayout(
          body: [
            const SizedBox(height: AppSpacing.xxl + AppSpacing.xxl),
            Center(
              child: SettleLogo(
                size: AppSizes.signInLogo,
                variant: logoVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl + AppSpacing.xl),
            Text(l10n.signInTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            GoogleSignInButton(
              isLoading: _running == _Action.google,
              onPressed: busy ? null : _signInWithGoogle,
            ),
            const SizedBox(height: AppSpacing.lg),
            const OrLabel(),
            const SizedBox(height: AppSpacing.lg),
            EmailField(controller: _emailController),
            const SizedBox(height: AppSpacing.lg),
            PasswordField(
              controller: _passwordController,
              isNewPassword: false,
              onSubmitted: busy ? null : _signInWithEmail,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LoadingButton(
                label: l10n.forgotPasswordButton,
                onPressed: busy ? null : () => context.push('/reset-password'),
                style: LoadingButtonStyle.text,
              ),
            ),
          ],
          actions: [
            if (_errorMessage != null) ...[
              FormMessage(_errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            LoadingButton(
              label: l10n.signInButton,
              isLoading: _running == _Action.email,
              onPressed: busy ? null : _signInWithEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap, so at a large font size "Sign up" moves to its own
            // line instead of running off the screen.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.signUpPrompt, style: theme.textTheme.bodyMedium),
                LoadingButton(
                  label: l10n.signUpButton,
                  onPressed: busy ? null : () => context.push('/sign-up'),
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
