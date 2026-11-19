import 'dart:math';

/// Join codes look like `CHAI-7KQ2M`: up to 4 letters from the group name,
/// then 5 random characters. Ambiguous characters (0/O, 1/I/L) are left out
/// so codes read and type cleanly from WhatsApp.
///
/// 31^5 ≈ 28.6 million codes per prefix, so codes can't practically be
/// guessed; anyone with a valid code can see the group's money (PLAN.md §6).
class JoinCode {
  JoinCode._();

  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const randomLength = 5;
  static const fallbackPrefix = 'SETL';

  static String generate(String groupName, {Random? random}) {
    final rng = random ?? Random.secure();
    final suffix = List.generate(
      randomLength,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
    return '${prefixFor(groupName)}-$suffix';
  }

  /// First 4 A–Z letters of the name, uppercased; `SETL` if it has none
  /// (e.g. an Urdu-script name).
  static String prefixFor(String groupName) {
    final letters = groupName.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    if (letters.isEmpty) return fallbackPrefix;
    return letters.length > 4 ? letters.substring(0, 4) : letters;
  }

  /// Normalises what a person typed: trims, uppercases, removes spaces, and
  /// adds the dash if missing. Returns null if it can't be a valid code.
  static String? normalize(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final match = RegExp('^([A-Z]{1,4})([$alphabet]{$randomLength})\$')
        .firstMatch(cleaned);
    if (match == null) return null;
    return '${match.group(1)}-${match.group(2)}';
  }
}
