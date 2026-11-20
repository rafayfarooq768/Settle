import 'package:flutter/animation.dart';

/// Motion tokens (DESIGN.md §7). Few, fast, and only where they confirm an
/// action. Curves are stronger than the built-ins, which feel weak.
abstract final class AppMotion {
  /// Strong ease-out: instant response, soft landing. For press feedback.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// iOS-like drawer curve, for bottom sheets.
  static const sheetCurve = Cubic(0.32, 0.72, 0, 1);

  /// Button press: scale down this much, this fast.
  static const pressScale = 0.97;
  static const press = Duration(milliseconds: 120);

  /// Sheets: exit faster than enter.
  static const sheetIn = Duration(milliseconds: 300);
  static const sheetOut = Duration(milliseconds: 200);

  /// A plain SnackBar (owner, 2026-11-20).
  static const snackBar = Duration(milliseconds: 2500);

  /// How long a SnackBar with Undo stays (DESIGN.md §8). Flutter keeps
  /// SnackBars with an action open until dismissed unless told not to;
  /// this is long enough to reach Undo, short enough not to linger.
  static const undoSnackBar = Duration(seconds: 4);
}
