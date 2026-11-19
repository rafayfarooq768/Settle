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

/// Avatar tints and QR colours (DESIGN.md §6). Avatars use one of six flat,
/// muted tints chosen by name hash; the QR stays dark-on-light in both
/// themes so every scanner can read it.
class ExtraColors extends ThemeExtension<ExtraColors> {
  const ExtraColors({
    required this.avatarTints,
    required this.onAvatar,
    required this.qrDark,
    required this.qrLight,
  });

  final List<Color> avatarTints;
  final Color onAvatar;
  final Color qrDark;
  final Color qrLight;

  static const light = ExtraColors(
    avatarTints: [
      Color(0xFFD6EBEF),
      Color(0xFFE2E8D3),
      Color(0xFFF0DFD4),
      Color(0xFFE2DEF2),
      Color(0xFFD9EADF),
      Color(0xFFF0E6CF),
    ],
    onAvatar: AppColors.ink,
    qrDark: AppColors.ink,
    qrLight: AppColors.white,
  );

  static const dark = ExtraColors(
    avatarTints: [
      Color(0xFF1F5A65),
      Color(0xFF414D30),
      Color(0xFF5C4033),
      Color(0xFF433D60),
      Color(0xFF2F5242),
      Color(0xFF5C4D2C),
    ],
    onAvatar: AppColors.white,
    qrDark: AppColors.ink,
    qrLight: AppColors.white,
  );

  @override
  ExtraColors copyWith({
    List<Color>? avatarTints,
    Color? onAvatar,
    Color? qrDark,
    Color? qrLight,
  }) => ExtraColors(
    avatarTints: avatarTints ?? this.avatarTints,
    onAvatar: onAvatar ?? this.onAvatar,
    qrDark: qrDark ?? this.qrDark,
    qrLight: qrLight ?? this.qrLight,
  );

  @override
  ExtraColors lerp(ThemeExtension<ExtraColors>? other, double t) =>
      t < 0.5 || other is! ExtraColors ? this : other;
}

extension ExtraColorsContext on BuildContext {
  ExtraColors get extraColors =>
      Theme.of(this).extension<ExtraColors>() ?? ExtraColors.light;
}
