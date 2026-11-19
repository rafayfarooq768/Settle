/// Public links. Not user-facing copy, so not in ARB files.
abstract final class AppLinks {
  /// Where friends download the APK (PLAN.md §1: GitHub Releases).
  /// The repo must be public for this to open for them.
  static const download =
      'https://github.com/rafayfarooq768/Settle/releases/latest';

  /// WhatsApp share with prefilled text, no API (PLAN.md §3 item 11).
  static Uri whatsAppShare(String text) =>
      Uri.https('wa.me', '/', {'text': text});
}
