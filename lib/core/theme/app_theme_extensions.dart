import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Money-specific colours (DESIGN.md §2) that Material's [ColorScheme]
/// has no slot for. Access via `Theme.of(context).extension<MoneyColors>()`.
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({required this.owed, required this.owe});

  final Color owed;
  final Color owe;

  static const light = MoneyColors(owed: AppColors.owed, owe: AppColors.owe);

  // Same hues, kept distinguishable on a dark surface (DESIGN.md §2: "keep
  // owed/owe hues, adjusted for contrast").
  static const dark = MoneyColors(
    owed: Color(0xFF4ADE80),
    owe: Color(0xFFFF6B6B),
  );

  @override
  MoneyColors copyWith({Color? owed, Color? owe}) {
    return MoneyColors(owed: owed ?? this.owed, owe: owe ?? this.owe);
  }

  @override
  MoneyColors lerp(ThemeExtension<MoneyColors>? other, double t) {
    if (other is! MoneyColors) return this;
    return MoneyColors(
      owed: Color.lerp(owed, other.owed, t) ?? owed,
      owe: Color.lerp(owe, other.owe, t) ?? owe,
    );
  }
}

extension MoneyColorsContext on BuildContext {
  MoneyColors get moneyColors =>
      Theme.of(this).extension<MoneyColors>() ?? MoneyColors.light;
}

/// Brand-only colours for avatars, links, QR and panels (BRAND.md §3,
/// DESIGN.md §2 and §6). No other tints.
class ExtraColors extends ThemeExtension<ExtraColors> {
  const ExtraColors({
    required this.avatar,
    required this.onAvatar,
    required this.link,
    required this.settled,
    required this.qrDark,
    required this.qrLight,
    required this.panel,
  });

  /// Person avatar fill and initials.
  final Color avatar;
  final Color onAvatar;

  /// Teal text for row-style actions ("New group or join").
  final Color link;

  /// "Settled up" text: brand teal, never a money colour.
  final Color settled;

  /// QR stays dark-on-light in both themes so any scanner reads it.
  final Color qrDark;
  final Color qrLight;

  /// Panel fill (DESIGN.md §4): Surface on light, one step above the dark
  /// background on dark.
  final Color panel;

  static const light = ExtraColors(
    avatar: AppColors.mist,
    onAvatar: AppColors.deepTeal,
    link: AppColors.deepTeal,
    settled: AppColors.deepTeal,
    qrDark: AppColors.ink,
    qrLight: AppColors.white,
    panel: AppColors.surface,
  );

  static const dark = ExtraColors(
    avatar: AppColors.deepTeal,
    onAvatar: AppColors.mist,
    link: AppColors.teal,
    settled: AppColors.mist,
    qrDark: AppColors.ink,
    qrLight: AppColors.white,
    panel: AppColors.darkPanel,
  );

  @override
  ExtraColors copyWith({
    Color? avatar,
    Color? onAvatar,
    Color? link,
    Color? settled,
    Color? qrDark,
    Color? qrLight,
    Color? panel,
  }) => ExtraColors(
    avatar: avatar ?? this.avatar,
    onAvatar: onAvatar ?? this.onAvatar,
    link: link ?? this.link,
    settled: settled ?? this.settled,
    qrDark: qrDark ?? this.qrDark,
    qrLight: qrLight ?? this.qrLight,
    panel: panel ?? this.panel,
  );

  @override
  ExtraColors lerp(ThemeExtension<ExtraColors>? other, double t) =>
      t < 0.5 || other is! ExtraColors ? this : other;
}

extension ExtraColorsContext on BuildContext {
  ExtraColors get extraColors =>
      Theme.of(this).extension<ExtraColors>() ?? ExtraColors.light;
}
