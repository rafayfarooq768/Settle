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
