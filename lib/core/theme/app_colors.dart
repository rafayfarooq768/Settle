import 'package:flutter/material.dart';

/// Flat colour tokens from DESIGN.md §2 and BRAND.md §3. Never hardcode these
/// in widgets; use `Theme.of(context)` (or [SettleLogo] for brand colours).
class AppColors {
  AppColors._();

  // Brand (BRAND.md §3)
  static const teal = Color(0xFF0B8295);
  static const deepTeal = Color(0xFF0A6170);
  static const night = Color(0xFF0A3A42);
  static const mist = Color(0xFFA7D9E2);
  static const ink = Color(0xFF14272B);
  static const white = Color(0xFFFFFFFF);
  static const slate = Color(0xFF5C7378);

  /// Second bar shade when the symbol sits on teal or has no tile (BRAND.md §1).
  static const barOnTeal = Color(0xFF6CBAC7);

  // Interface (DESIGN.md §2)
  static const primary = teal;
  static const secondary = Color(0xFF4E8C85);
  static const tertiary = Color(0xFF7B6FD6);
  static const background = Color(0xFFF7F8F8);
  static const surface = white;
  static const text = ink;
  static const textMuted = Color(0xFF5F6B6D);
  static const outline = Color(0xFFD5DBDC);
  static const owed = Color(0xFF12884E);
  static const owe = Color(0xFFD63B3B);
}
