import 'package:flutter/material.dart';

/// Flat colour tokens from DESIGN.md §2. Never hardcode these in widgets —
/// use [AppTheme] / `Theme.of(context)` instead.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0A7A91);
  static const primaryBright = Color(0xFF0E8FA8);
  static const secondary = Color(0xFF4E8C85);
  static const tertiary = Color(0xFF7B6FD6);
  static const background = Color(0xFFF7F8F8);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1B1F20);
  static const textMuted = Color(0xFF5F6B6D);
  static const outline = Color(0xFFD5DBDC);
  static const owed = Color(0xFF12884E);
  static const owe = Color(0xFFD63B3B);
}
