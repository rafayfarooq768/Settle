import 'package:material_ui/material_ui.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// End padding for a row that ends with [RowEnd]: the chevron's own
/// space sits where the 16 margin would be, so the chevron lines up with
/// Home's group rows (DESIGN.md §6: a chevron says the row opens).
const EdgeInsetsDirectional chevronRowPadding = EdgeInsetsDirectional.only(
  start: AppSpacing.lg,
  end: AppSpacing.sm,
);

/// The end of a tappable row: [child] (a money label), 8, then a muted
/// chevron. With [opens] false the chevron's space stays empty, so amounts
/// in rows that don't open (payments) still line up with those that do.
class RowEnd extends StatelessWidget {
  const RowEnd({super.key, this.child, this.opens = true});

  final Widget? child;
  final bool opens;

  /// The money label never takes more than this share of the screen
  /// width, so at a large font size the name keeps room for whole words
  /// and the label shrinks to fit instead ([MoneyStack] scales down).
  static const maxWidthShare = 0.3;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (child != null)
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * maxWidthShare,
          ),
          child: child,
        ),
      const SizedBox(width: AppSpacing.sm),
      opens
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : const SizedBox(width: AppSizes.icon),
    ],
  );
}
