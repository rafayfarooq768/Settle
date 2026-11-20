import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/theme/app_colors.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/theme/app_theme_extensions.dart';

/// DESIGN.md §2: brand colours only. Material's seed would otherwise add a
/// bright cyan container, a lavender tertiary and its own error red.
void main() {
  test('light scheme uses the DESIGN.md colours', () {
    final c = AppTheme.light().colorScheme;
    expect(c.primary, AppColors.teal);
    expect(c.secondary, AppColors.secondary);
    expect(c.tertiary, AppColors.deepTeal);
    expect(c.primaryContainer, AppColors.mist);
    expect(c.error, AppColors.owe);
    expect(c.onSurface, AppColors.ink);
    expect(c.onSurfaceVariant, AppColors.textMuted);
  });

  test('dark scheme: brand accents on neutral near-black', () {
    final t = AppTheme.dark();
    final c = t.colorScheme;
    expect(c.primary, AppColors.teal);
    expect(c.secondary, AppColors.secondary);
    expect(c.tertiary, AppColors.mist);
    expect(c.error, MoneyColors.dark.owe);
    expect(t.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(t.bottomSheetTheme.backgroundColor, AppColors.darkPanel);
    expect(t.dialogTheme.backgroundColor, AppColors.darkPanel);
  });

  test('sheets and dialogs are Surface white in light mode', () {
    final t = AppTheme.light();
    expect(t.bottomSheetTheme.backgroundColor, AppColors.surface);
    expect(t.dialogTheme.backgroundColor, AppColors.surface);
  });

  // Bug (2026-11-20 dark mode pass): teal text was under 4.5:1 on the
  // dark surfaces.
  test('dark mode text links are readable (at least 4.5:1)', () {
    double lum(Color c) {
      double ch(double v) => v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
    }

    double ratio(Color a, Color b) {
      final (x, y) = (lum(a), lum(b));
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    final theme = AppTheme.dark();
    final link = theme.extension<ExtraColors>()!.link;
    final button = theme.textButtonTheme.style!.foregroundColor!.resolve({})!;
    for (final bg in [
      AppColors.darkBackground,
      AppColors.darkPanel,
      AppColors.darkContainer,
    ]) {
      expect(ratio(link, bg), greaterThanOrEqualTo(4.5));
      expect(ratio(button, bg), greaterThanOrEqualTo(4.5));
    }
  });
}
