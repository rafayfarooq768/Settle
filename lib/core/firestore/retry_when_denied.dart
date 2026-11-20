import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Re-opens a Firestore listen that was refused with permission-denied,
/// waiting 0.5 s, 1 s, 2 s... between tries ([maxRetries] in total).
///
/// Why: right after creating or joining a group, the screen starts
/// listening before the server has the new membership, so the rules refuse
/// the read. Firestore never retries a refused listen by itself. Any other
/// error, or a refusal that outlasts the retries, is passed on.
Stream<T> retryWhenDenied<T>(
  Stream<T> Function() open, {
  int maxRetries = 6,
  Duration firstDelay = const Duration(milliseconds: 500),
}) {
  late final StreamController<T> out;
  StreamSubscription<T>? sub;
  Timer? timer;
  var retries = 0;
  var retrying = false;

  void listen() {
    retrying = false;
    sub = open().listen(
      out.add,
      onError: (Object e, StackTrace st) {
        if (e is FirebaseException &&
            e.code == 'permission-denied' &&
            retries < maxRetries) {
          retrying = true;
          sub?.cancel();
          timer = Timer(firstDelay * (1 << retries++), listen);
        } else {
          out.addError(e, st);
        }
      },
      onDone: () {
        if (!retrying) out.close();
      },
    );
  }

  out = StreamController<T>(
    onListen: listen,
    onCancel: () async {
      timer?.cancel();
      await sub?.cancel();
    },
  );
  return out.stream;
}
