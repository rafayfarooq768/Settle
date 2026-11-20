import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A tappable field that opens a picker (DESIGN.md §6 Inputs). It looks
/// like the text fields around it: outlined box, floating label, value
/// inside, ▾ at the end, so it reads as something you can change.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
    this.helper,
    this.error,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Avatar or icon before the value.
  final Widget? leading;

  /// Muted line under the box, e.g. "Rs 500 each".
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            helperText: error == null ? helper : null,
            errorText: error,
            prefixIcon: leading == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.md,
                      end: AppSpacing.sm,
                    ),
                    child: leading,
                  ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
