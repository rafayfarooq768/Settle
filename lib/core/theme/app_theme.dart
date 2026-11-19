import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_theme_extensions.dart';

/// Theme defined once from DESIGN.md tokens (§2, §3, §5, §6). Widgets must
/// read colours, shapes and text styles from `Theme.of(context)`, never
/// hardcode them.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.tertiary,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          outline: AppColors.outline,
        );
    return _base(colorScheme, MoneyColors.light);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    return _base(colorScheme, MoneyColors.dark);
  }

  static ThemeData _base(ColorScheme colorScheme, MoneyColors moneyColors) {
    final isLight = colorScheme.brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.background
          : colorScheme.surface,
      extensions: [moneyColors],
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.background : colorScheme.surface,
        foregroundColor: isLight ? AppColors.text : colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isLight ? AppColors.text : colorScheme.onSurface,
        ),
      ),
      textTheme: _textTheme(colorScheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard),
          ),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard),
          ),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    const fontFeatures = [FontFeature.tabularFigures()];
    final typography = Typography.material2021(colorScheme: colorScheme);
    final isLight = colorScheme.brightness == Brightness.light;
    var theme = isLight ? typography.black : typography.white;
    theme = theme.copyWith(
      titleLarge: theme.titleLarge?.copyWith(fontSize: 22),
      headlineMedium: theme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFeatures: fontFeatures,
      ),
      bodyLarge: theme.bodyLarge?.copyWith(
        fontSize: 16,
        fontFeatures: fontFeatures,
      ),
      bodyMedium: theme.bodyMedium?.copyWith(fontSize: 14),
      labelLarge: theme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
    return theme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }
}
