import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import 'press_scale.dart';

enum RowButtonKind {
  /// The row's main action: teal, semibold.
  primary,

  /// The quieter one next to it: muted.
  secondary,
}

/// A text action inside a list row (I paid / Record payment / Remind,
/// DESIGN.md §11). No fill or outline: the money line stays the strongest
/// thing in the row, and the main action is set apart by colour and
/// weight, not by a box. Tap target stays 48dp.
class RowButton extends StatelessWidget {
  const RowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = RowButtonKind.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final RowButtonKind kind;

  /// Horizontal padding inside the button; rows shift the actions back by
  /// this much so the first label lines up with the text above.
  static const inset = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = kind == RowButtonKind.primary;
    return PressScale(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: primary
              ? theme.textButtonTheme.style?.foregroundColor?.resolve({})
              : theme.colorScheme.onSurfaceVariant,
          minimumSize: const Size(0, AppSizes.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: inset),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
