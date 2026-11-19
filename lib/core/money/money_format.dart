/// Display and input for money (PLAN.md §4, DESIGN.md §3). Parsing works on
/// the digits directly: never through `double`.
library;

/// `Rs 1,200`, or `Rs 333.34` when paisa are non-zero. Uses the absolute
/// value: callers say the direction in words ("You owe …") or use
/// [formatSignedRupees].
String formatRupees(int paisa) {
  final abs = paisa.abs();
  final rupees = _group(abs ~/ 100);
  final rest = abs % 100;
  return rest == 0
      ? 'Rs $rupees'
      : 'Rs $rupees.${rest.toString().padLeft(2, '0')}';
}

/// `+ Rs 700`, `− Rs 300` (U+2212 minus), or `Rs 0`. DESIGN.md §2: never
/// rely on colour alone, so the sign is always written.
String formatSignedRupees(int paisa) {
  if (paisa == 0) return formatRupees(0);
  return '${paisa > 0 ? '+' : '−'} ${formatRupees(paisa)}';
}

String _group(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Parses user input like `1200`, `1,200`, `1200.5` or `Rs 99.99` into
/// paisa. Returns null for empty, negative, or more than 2 decimal places.
int? parseRupees(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'^\s*Rs\.?\s*', caseSensitive: false), '')
      .replaceAll(',', '')
      .trim();
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

/// Parses a percentage like `33.33` or `10%` into basis points (3333, 1000).
/// Returns null for empty, negative, over 100, or more than 2 decimals.
int? parsePercent(String input) {
  final cleaned = input.replaceAll('%', '').trim();
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final bp = whole * 100 + int.parse((match.group(2) ?? '').padRight(2, '0'));
  return bp > 10000 ? null : bp;
}
