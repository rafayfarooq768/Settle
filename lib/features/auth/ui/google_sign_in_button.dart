import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// "Continue with Google" with the Google "G", as Google's sign-in branding
/// guidelines require. Secondary weight (outlined): the screen's one primary
/// action stays the email form's filled button (DESIGN.md §6).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: AppSizes.buttonProgress,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.buttonProgressStroke,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/google_g.svg',
                  width: AppSizes.googleMark,
                  height: AppSizes.googleMark,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(l10n.signInWithGoogle),
              ],
            ),
    );
  }
}
