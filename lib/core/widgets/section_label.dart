import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Groups related rows with a quiet label instead of a box (DESIGN.md §4).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
