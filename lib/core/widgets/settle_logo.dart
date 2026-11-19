import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Which background the logo sits on (BRAND.md §1 "Colour pairs").
enum SettleLogoVariant {
  /// Light background (white / paper): teal tile, white + mist bars.
  light,

  /// Teal background: white tile, teal + #6CBAC7 bars.
  teal,

  /// Night background: teal tile, white + mist bars.
  night,

  /// Monochrome dark: no tile, ink bars and text.
  mono,
}

/// The Settle logo lockup: symbol tile + "Settle" + "HISAAB BARABAR".
///
/// All measurements derive from the tile size [size] (T) per BRAND.md §2.
/// The tagline is always hidden below T = 48. The lockup includes its
/// 0.25 T clear space unless [withClearSpace] is false.
///
/// The wordmark and tagline are the brand mark, not UI copy, so they are not
/// translated and stay left-to-right in RTL locales.
class SettleLogo extends StatelessWidget {
  const SettleLogo({
    super.key,
    required this.size,
    this.variant = SettleLogoVariant.light,
    this.showTagline = true,
    this.showName = true,
    this.withClearSpace = true,
  });

  /// The symbol tile size T, in logical pixels. Minimum 16 (BRAND.md §2).
  final double size;
  final SettleLogoVariant variant;

  /// Requested tagline; ignored (hidden) when [size] < 48.
  final bool showTagline;

  /// False draws the symbol only.
  final bool showName;
  final bool withClearSpace;

  static const _name = 'Settle';
  static const _tagline = 'HISAAB BARABAR';
  static const _brandFont = 'Manrope';

  bool get _taglineVisible => showTagline && size >= 48;

  @override
  Widget build(BuildContext context) {
    final colors = _LogoColors.of(variant);
    final t = size;

    final symbol = CustomPaint(
      size: Size.square(t),
      painter: _SymbolPainter(colors),
    );

    Widget lockup = symbol;
    if (showName) {
      final taglineSize = (0.155 * t) < 10 ? 10.0 : 0.155 * t;
      lockup = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          symbol,
          SizedBox(width: 0.25 * t),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                style: TextStyle(
                  fontFamily: _brandFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 0.75 * t,
                  letterSpacing: -0.03 * 0.75 * t,
                  height: 0.9,
                  color: colors.name,
                ),
              ),
              if (_taglineVisible) ...[
                SizedBox(height: 0.1 * t),
                Text(
                  _tagline,
                  style: TextStyle(
                    fontFamily: _brandFont,
                    fontWeight: FontWeight.w600,
                    fontSize: taglineSize,
                    letterSpacing: 0.2 * taglineSize,
                    height: 1,
                    color: colors.tagline,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Semantics(
      label: _name,
      image: true,
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.all(withClearSpace ? 0.25 * t : 0),
            child: lockup,
          ),
        ),
      ),
    );
  }
}

class _LogoColors {
  const _LogoColors({
    required this.tile,
    required this.mainBar,
    required this.secondBar,
    required this.name,
    required this.tagline,
  });

  /// Null means no tile.
  final Color? tile;
  final Color mainBar;
  final Color secondBar;
  final Color name;
  final Color tagline;

  static _LogoColors of(SettleLogoVariant variant) {
    switch (variant) {
      case SettleLogoVariant.light:
        return const _LogoColors(
          tile: AppColors.teal,
          mainBar: AppColors.white,
          secondBar: AppColors.mist,
          name: AppColors.ink,
          tagline: AppColors.slate,
        );
      case SettleLogoVariant.teal:
        return const _LogoColors(
          tile: AppColors.white,
          mainBar: AppColors.teal,
          secondBar: AppColors.barOnTeal,
          name: AppColors.white,
          tagline: AppColors.white,
        );
      case SettleLogoVariant.night:
        return const _LogoColors(
          tile: AppColors.teal,
          mainBar: AppColors.white,
          secondBar: AppColors.mist,
          name: AppColors.white,
          tagline: AppColors.mist,
        );
      case SettleLogoVariant.mono:
        return const _LogoColors(
          tile: null,
          mainBar: AppColors.ink,
          secondBar: AppColors.ink,
          name: AppColors.ink,
          tagline: AppColors.ink,
        );
    }
  }
}

/// Paints the symbol from the BRAND.md §1 geometry on the 108-unit grid.
class _SymbolPainter extends CustomPainter {
  const _SymbolPainter(this.colors);

  final _LogoColors colors;

  static const _grid = 108.0;
  static const _tileRadius = 24.0;
  static const _barRadius = 3.0;

  // (x, y, width, height, isMainShade) — top row unequal, bottom row equal.
  static const _bars = [
    (30.0, 37.0, 30.0, 12.0, true),
    (66.0, 37.0, 12.0, 12.0, false),
    (30.0, 59.0, 21.0, 12.0, true),
    (57.0, 59.0, 21.0, 12.0, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.scale(scale);

    final tile = colors.tile;
    if (tile != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, _grid, _grid),
          const Radius.circular(_tileRadius),
        ),
        Paint()..color = tile,
      );
    }

    for (final (x, y, w, h, isMain) in _bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(_barRadius),
        ),
        Paint()..color = isMain ? colors.mainBar : colors.secondBar,
      );
    }
  }

  @override
  bool shouldRepaint(_SymbolPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
