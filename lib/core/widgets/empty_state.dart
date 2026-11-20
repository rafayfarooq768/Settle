import 'package:material_ui/material_ui.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// An empty or quiet state (DESIGN.md §9; DESIGN (3).md polish 2026-11-20):
/// the first line in titleMedium, an optional muted second line, then the
/// actions 16 below. Left-aligned with the panels, near the top, never
/// floating in the middle of the screen. No illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.actions = const [],
    this.titleColor,
  });

  final String title;
  final String? message;

  /// Buttons, strongest first; stacked with 8 between.
  final List<Widget> actions;

  /// For "Everyone is settled up" (the settled colour).
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
        AppSpacing.screenHorizontal,
        AppSpacing.xxl,
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.emptyTextWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty) const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          actions[i],
        ],
      ],
    );
  }
}
