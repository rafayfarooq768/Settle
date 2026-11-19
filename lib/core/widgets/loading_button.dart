import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

enum LoadingButtonStyle { filled, outlined }

/// A full-width button that shows the standard progress indicator while its
/// real network action runs (DESIGN.md §7). Disabled when [onPressed] is null.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.style = LoadingButtonStyle.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LoadingButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: AppSizes.buttonProgress,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.buttonProgressStroke,
            ),
          )
        : Text(label);
    final onTap = isLoading ? null : onPressed;
    return switch (style) {
      LoadingButtonStyle.filled => FilledButton(onPressed: onTap, child: child),
      LoadingButtonStyle.outlined => OutlinedButton(
        onPressed: onTap,
        child: child,
      ),
    };
  }
}
