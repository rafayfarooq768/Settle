/// Component sizes that aren't spacing (DESIGN.md §4 covers spacing only).
class AppSizes {
  AppSizes._();

  /// Minimum height of full-width form buttons (DESIGN.md §4 tap target).
  static const double buttonHeight = 48;

  /// Progress indicator shown inside a button while its action runs.
  static const double buttonProgress = 20;
  static const double buttonProgressStroke = 2;

  /// Google "G" mark in the sign-in button (Google branding guidelines: 18dp).
  static const double googleMark = 18;

  /// Logo tile size T on the sign-in screen (BRAND.md §6).
  static const double signInLogo = 64;

  /// Member avatar circle (DESIGN.md §6 Avatars).
  static const double avatar = 40;

  /// Join-code QR on the invite screen: big enough to scan across a table.
  static const double qrCode = 200;

  /// Width of the placeholder avatar's outline.
  static const double avatarOutline = 1;

  /// Small avatars in a group's member row (DESIGN.md §6).
  static const double avatarSmall = 28;

  /// How much small avatars overlap in the member row.
  static const double avatarOverlap = 8;

  /// Lockup size in Settings (BRAND.md §6: T = 32, no tagline).
  static const double settingsLogo = 32;

  /// Material Symbols size (DESIGN.md §6 Icons).
  static const double icon = 24;

  /// Home group row: a bit taller than a plain row for the bolder name.
  static const double groupRowHeight = 72;

  /// Minimum touch target (DESIGN.md §4).
  static const double tapTarget = 48;

  /// Per-person number field on the split screen.
  static const double splitInputWidth = 120;
}
