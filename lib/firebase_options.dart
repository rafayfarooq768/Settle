// Placeholder — will be replaced by `flutterfire configure` once the
// Firebase project exists (PLAN.md §9 step 1, Firebase connection substep).
// Do not fill this in by hand.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      throw UnsupportedError(
        'firebase_options.dart is a placeholder. Run `flutterfire configure` '
        'after creating the Firebase project to generate the real one.',
      );
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.',
    );
  }
}
