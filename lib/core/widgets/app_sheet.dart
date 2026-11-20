import 'package:material_ui/material_ui.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// Every bottom sheet goes through here so they all move the same way:
/// drawer curve, quicker exit than entry (DESIGN.md §7, §8).
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool scrollControlled = false,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    showDragHandle: true,
    sheetAnimationStyle: reduceMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            curve: AppMotion.sheetCurve,
            duration: AppMotion.sheetIn,
            reverseDuration: AppMotion.sheetOut,
          ),
    builder: builder,
  );
}

/// The title at the top of every sheet, aligned with the rows' text, so
/// all sheets start the same way (DESIGN.md §8).
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.inset = true});

  final String text;

  /// True for list sheets (aligns with ListTile text); false when the
  /// sheet already has the screen margin (form sheets).
  final bool inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(
      inset ? AppSpacing.lg : 0,
      0,
      inset ? AppSpacing.lg : 0,
      AppSpacing.md,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
