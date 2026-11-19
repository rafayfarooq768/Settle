import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

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
