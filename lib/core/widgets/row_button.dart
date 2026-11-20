import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import 'press_scale.dart';

enum RowButtonKind { tonal, outlined, text }

/// A compact button inside a list row (Pay / Remind / Record, DESIGN.md
/// §11). Same shapes as the full-width buttons, sized to its label; the
/// touch target stays 48dp through Material's padded tap target.
class RowButton extends StatelessWidget {
  const RowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = RowButtonKind.tonal,
  });

  final String label;
  final VoidCallback? onPressed;
  final RowButtonKind kind;

  static const _size = WidgetStatePropertyAll(
    Size(AppSizes.rowButtonMinWidth, AppSizes.rowButtonHeight),
  );
  static const _style = ButtonStyle(
    minimumSize: _size,
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    final button = switch (kind) {
      RowButtonKind.tonal => FilledButton.tonal(
        onPressed: onPressed,
        style: _style,
        child: text,
      ),
      RowButtonKind.outlined => OutlinedButton(
        onPressed: onPressed,
        style: _style,
        child: text,
      ),
      RowButtonKind.text => TextButton(
        onPressed: onPressed,
        style: _style,
        child: text,
      ),
    };
    return PressScale(child: button);
  }
}
