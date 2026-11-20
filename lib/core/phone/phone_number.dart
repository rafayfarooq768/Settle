/// Phone numbers typed by people (owner, 2026-11-20): optional, not
/// verified, used only to open a WhatsApp chat for reminders. No SMS.
///
/// Stored in international form, "+923001234567". Pakistani numbers can be
/// typed the usual ways: 0300 1234567, 0300-1234567, 300 1234567,
/// +92 300 1234567, 0092 300 1234567, 92300 1234567.
library;

/// The number in international form ("+923001234567"), or null if it
/// can't be a phone number. Spaces, dashes, dots and brackets are ignored.
String? normalizePhone(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (!RegExp(r'^[+\d\s\-().]+$').hasMatch(trimmed)) return null;
  final plus = trimmed.startsWith('+');
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');

  if (!plus) {
    if (digits.startsWith('00')) {
      digits = digits.substring(2); // 0092 300 ... → 92300...
    } else if (digits.length == 11 && digits.startsWith('03')) {
      digits = '92${digits.substring(1)}'; // 0300 1234567
    } else if (digits.length == 10 && digits.startsWith('3')) {
      digits = '92$digits'; // 300 1234567
    } else if (!(digits.length == 12 && digits.startsWith('923'))) {
      return null; // a local number we can't place
    }
  }

  // Pakistani mobiles are 92 + 3xx + 7 digits.
  if (digits.startsWith('92') && !_pkMobile.hasMatch(digits)) return null;
  // E.164: 8 to 15 digits, no leading zero.
  if (digits.length < 8 || digits.length > 15 || digits.startsWith('0')) {
    return null;
  }
  return '+$digits';
}

final _pkMobile = RegExp(r'^923\d{9}$');

/// For display: "+92 300 1234567" for Pakistani mobiles, otherwise as
/// stored. Empty stays empty.
String formatPhone(String stored) {
  if (_pkMobile.hasMatch(stored.replaceFirst('+', ''))) {
    final d = stored.replaceFirst('+', '');
    return '+92 ${d.substring(2, 5)} ${d.substring(5)}';
  }
  return stored;
}

/// The digits wa.me wants ("923001234567"), or null when there is no
/// usable number.
String? whatsAppDigits(String stored) {
  final normal = normalizePhone(stored);
  return normal?.substring(1);
}
