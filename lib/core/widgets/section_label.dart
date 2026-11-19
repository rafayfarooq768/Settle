import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A quiet label above a panel (DESIGN.md §4), aligned with the panel's
/// text: screen margin + row padding.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screenHorizontal + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.screenHorizontal + AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
