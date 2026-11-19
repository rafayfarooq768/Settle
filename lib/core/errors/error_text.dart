import 'package:firebase_core/firebase_core.dart';

import '../../l10n/app_localizations.dart';

/// Plain-words message for a failed Firestore action (DESIGN.md §10).
String errorText(AppLocalizations l10n, Object error) {
  if (error is FirebaseException &&
      const {'unavailable', 'deadline-exceeded'}.contains(error.code)) {
    return l10n.errorNetwork;
  }
  return l10n.errorGeneric;
}
