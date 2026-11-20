import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/firestore/retry_when_denied.dart';

FirebaseException _err(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

/// A listen that fails with [error] and then closes, like Firestore does.
Stream<int> _failing(FirebaseException error) => Stream<int>.error(error);

void main() {
  test('a refused listen is reopened and then delivers data', () async {
    var opens = 0;
    final stream = retryWhenDenied(() {
      opens++;
      return opens < 3 ? _failing(_err('permission-denied')) : Stream.value(42);
    }, firstDelay: Duration.zero);
    expect(await stream.first, 42);
    expect(opens, 3);
  });

  test('other errors are passed on at once', () async {
    var opens = 0;
    final stream = retryWhenDenied(() {
      opens++;
      return _failing(_err('unavailable'));
    }, firstDelay: Duration.zero);
    await expectLater(stream, emitsError(isA<FirebaseException>()));
    expect(opens, 1);
  });

  test('a refusal that outlasts the retries is passed on', () async {
    var opens = 0;
    final stream = retryWhenDenied(
      () {
        opens++;
        return _failing(_err('permission-denied'));
      },
      maxRetries: 2,
      firstDelay: Duration.zero,
    );
    await expectLater(stream, emitsError(isA<FirebaseException>()));
    expect(opens, 3);
  });
}
