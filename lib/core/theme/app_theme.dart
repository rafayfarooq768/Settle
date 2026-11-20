import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
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
          onPrimary: AppColors.white,
          secondary: AppColors.secondary,
          // No purple: brand palette only (DESIGN.md §2, owner 2026-11-19).
          tertiary: AppColors.deepTeal,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textMuted,
          outline: AppColors.outline,
        );
    return _base(
      colorScheme,
      MoneyColors.light,
      ExtraColors.light,
      background: AppColors.background,
      // DESIGN.md §2: Deep teal for teal text and links on light backgrounds.
      linkColor: AppColors.deepTeal,
    );
  }

  static ThemeData dark() {
    // DESIGN.md §2: same seed for the accents; neutral near-black surfaces
    // (the seed would tint every surface teal).
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          // Same brand Teal buttons as light mode, not the seed's pale cyan.
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          surface: AppColors.darkBackground,
          surfaceContainerLowest: AppColors.darkBackground,
          surfaceContainerLow: AppColors.darkPanel,
          surfaceContainer: AppColors.darkPanel,
          surfaceContainerHigh: AppColors.darkContainer,
          surfaceContainerHighest: AppColors.darkContainerHigh,
          outline: AppColors.darkOutline,
          outlineVariant: AppColors.darkOutline,
        );
    return _base(
      colorScheme,
      MoneyColors.dark,
      ExtraColors.dark,
      background: AppColors.darkBackground,
      linkColor: colorScheme.primary,
    );
  }

  static ThemeData _base(
    ColorScheme colorScheme,
    MoneyColors moneyColors,
    ExtraColors extraColors, {
    required Color background,
    required Color linkColor,
  }) {
    final text = _textTheme(colorScheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      extensions: [moneyColors, extraColors],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      textTheme: text,
      tabBarTheme: TabBarThemeData(
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
        labelColor: linkColor,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: linkColor,
        dividerColor: colorScheme.outline,
      ),
      // DESIGN (3).md §4 row anatomy: 16 from the edge, 12 from the
      // avatar/icon to the text; names weight 500 so a row scans as
      // who → how much.
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        horizontalTitleGap: AppSpacing.md,
        iconColor: colorScheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      // DESIGN.md §2/§5: the FAB is brand Teal in both modes, fully rounded.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: StadiumBorder(),
      ),
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
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard),
          ),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: linkColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      // Owner 2026-11-20: no pale tinted fills on selected segments and
      // chips. Selected is solid brand Teal with white text, like the FAB;
      // unselected is plain with an outline. Radius 8 (DESIGN.md §5).
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.standard),
            ),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colorScheme.outline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.white
                : colorScheme.onSurface,
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const BorderSide(color: AppColors.primary)
              : BorderSide(color: colorScheme.outline),
        ),
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        checkmarkColor: AppColors.white,
        // Chips read the label colour as a WidgetStateColor (a
        // WidgetStateTextStyle is ignored and left the names unreadable).
        labelStyle: text.labelLarge?.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.white
                : colorScheme.onSurface,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          borderSide: BorderSide(color: linkColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
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

  /// DESIGN.md §3 (owner 2026-11-20): Manrope for headings and the big
  /// numbers, Roboto (platform default) for body, lists and buttons.
  static TextTheme _textTheme(ColorScheme colorScheme) {
    const tabular = [FontFeature.tabularFigures()];
    final typography = Typography.material2021(colorScheme: colorScheme);
    final isLight = colorScheme.brightness == Brightness.light;
    var theme = isLight ? typography.black : typography.white;
    TextStyle? brand(
      TextStyle? base,
      double size,
      FontWeight weight, {
      double spacing = 0,
      double height = 1.25,
      bool numbers = false,
    }) => base?.copyWith(
      fontFamily: AppFonts.brand,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      fontFeatures: numbers ? tabular : null,
    );
    theme = theme.copyWith(
      // The amount being typed on Add expense; the Group header balance.
      headlineLarge: brand(
        theme.headlineLarge,
        32,
        FontWeight.w700,
        spacing: -0.5,
        height: 1.1,
        numbers: true,
      ),
      // The big balance on Home.
      headlineMedium: brand(
        theme.headlineMedium,
        28,
        FontWeight.w700,
        spacing: -0.5,
        height: 1.1,
        numbers: true,
      ),
      headlineSmall: brand(
        theme.headlineSmall,
        24,
        FontWeight.w700,
        spacing: -0.3,
        numbers: true,
      ),
      // Screen titles.
      titleLarge: brand(
        theme.titleLarge,
        22,
        FontWeight.w700,
        spacing: -0.2,
        height: 1.2,
      ),
      // Sheet titles, empty-state titles.
      titleMedium: brand(theme.titleMedium, 16, FontWeight.w600, height: 1.3),
      // Section labels and tabs. 14 (not DESIGN (3)'s 13) to stay on the
      // Material scale (owner left it to us, 2026-11-20).
      titleSmall: brand(
        theme.titleSmall,
        14,
        FontWeight.w600,
        spacing: 0.2,
        height: 1.2,
      ),
      bodyLarge: theme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.3,
        fontFeatures: tabular,
      ),
      bodyMedium: theme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.35,
        fontFeatures: tabular,
      ),
      bodySmall: theme.bodySmall?.copyWith(
        fontSize: 12,
        letterSpacing: 0.1,
        height: 1.35,
        fontFeatures: tabular,
      ),
      labelLarge: theme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.2,
      ),
    );
    return theme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }
}
