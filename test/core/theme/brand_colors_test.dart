import 'package:flutter_test/flutter_test.dart';
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
}
