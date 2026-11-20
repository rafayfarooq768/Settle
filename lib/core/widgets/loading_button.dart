import 'package:material_ui/material_ui.dart';

import '../theme/app_sizes.dart';
import 'press_scale.dart';

enum LoadingButtonStyle { filled, outlined, text }

/// The app's button: full width, press feedback, and the standard progress
/// indicator while its real network action runs (DESIGN.md §6, §7).
/// Disabled when [onPressed] is null.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.style = LoadingButtonStyle.filled,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LoadingButtonStyle style;

  /// Only for destructive text buttons (owe-red, DESIGN.md §6).
  final Color? foregroundColor;

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
    final button = switch (style) {
      LoadingButtonStyle.filled => FilledButton(onPressed: onTap, child: child),
      LoadingButtonStyle.outlined => OutlinedButton(
        onPressed: onTap,
        child: child,
      ),
      LoadingButtonStyle.text => TextButton(
        style: foregroundColor == null
            ? null
            : TextButton.styleFrom(foregroundColor: foregroundColor),
        onPressed: onTap,
        child: child,
      ),
    };
    return PressScale(enabled: onTap != null, child: button);
  }
}
