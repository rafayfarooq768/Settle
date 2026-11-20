/// Spacing scale from DESIGN.md §4. Only these values are allowed.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Empty space under a list on a screen with a FAB, so the FAB never
  /// covers the last row.
  static const double fabClearance = xxl * 3;

  /// Standard screen horizontal padding (DESIGN.md §4).
  static const double screenHorizontal = lg;

  /// Minimum list row height (DESIGN.md §4).
  static const double rowHeight = 56;

  /// Minimum tap target (DESIGN.md §4).
  static const double tapTarget = 48;
}
