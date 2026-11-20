import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// A section's rows on one Surface panel (DESIGN.md §4): no border, no
/// shadow, rows separated by dividers inset to the text. One level only.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.children, this.dividerIndent});

  final List<Widget> children;

  /// Start inset of the dividers between rows; null = no dividers.
  final double? dividerIndent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Material(
        color: context.extraColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        clipBehavior: Clip.antiAlias,
        // 4 at top and bottom so the first and last rows don't touch the
        // rounded corners (DESIGN (3).md §4).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0 && dividerIndent != null)
                Divider(indent: dividerIndent, height: 1),
              children[i],
            ],
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Inset for dividers in rows that start with a 40dp avatar or tile.
const double avatarRowDividerIndent =
    AppSpacing.lg + AppSizes.avatar + AppSpacing.md; // padding + avatar + gap

/// Inset for dividers in rows that start with a 24dp icon.
const double iconRowDividerIndent =
    AppSpacing.lg + AppSizes.icon + AppSpacing.md; // padding + icon + gap
