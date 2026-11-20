import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// A small muted line under a panel, aligned with the panel's text, saying
/// something about the whole panel (who sees it, how it's shared).
class PanelNote extends StatelessWidget {
  const PanelNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal + AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.screenHorizontal + AppSpacing.lg,
        0,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
