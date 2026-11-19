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
    final textTheme = Theme.of(context).textTheme;
    final busy = _running != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(l10n.signInTitle, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xl),
                LoadingButton(
                  label: l10n.signInWithGoogle,
                  style: LoadingButtonStyle.outlined,
                  isLoading: _running == _Action.google,
                  onPressed: busy ? null : _signInWithGoogle,
                ),
                const SizedBox(height: AppSpacing.xl),
                EmailField(controller: _emailController),
                const SizedBox(height: AppSpacing.lg),
                PasswordField(
                  controller: _passwordController,
                  isNewPassword: false,
                  onSubmitted: busy ? null : _signInWithEmail,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => context.push('/reset-password'),
                    child: Text(l10n.forgotPasswordButton),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FormMessage(_errorMessage!),
                ],
                const SizedBox(height: AppSpacing.lg),
                LoadingButton(
                  label: l10n.signInButton,
                  isLoading: _running == _Action.email,
                  onPressed: busy ? null : _signInWithEmail,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.signUpPrompt, style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: busy ? null : () => context.push('/sign-up'),
                      child: Text(l10n.signUpButton),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
