import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/core/firestore/firestore_provider.dart';
import 'package:settle/core/router/app_router.dart';
import 'package:settle/features/auth/domain/auth_repository.dart';
import 'package:settle/features/auth/ui/auth_providers.dart';
import 'package:settle/main.dart';

/// A signed-in Firebase user, with only what the app reads.
class FakeUser extends Fake implements User {
  FakeUser({required this.uid, this.displayName, this.email});

  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? email;
}

/// Sign-in without Firebase. Records what the screens asked for, and can
/// be told to fail the next call with [failWith].
class FakeAuth implements AuthRepository {
  FakeAuth({User? user, this.hasPassword = true})
    : _user = user; // ignore: prefer_initializing_formals

  User? _user;
  final _changes = StreamController<User?>.broadcast();
  final calls = <String>[];

  /// The next call throws this, then it clears.
  AuthFailure? failWith;

  @override
  bool hasPassword;

  void _setUser(User? user) {
    _user = user;
    _changes.add(user);
  }

  Future<void> _call(String name, [void Function()? then]) async {
    calls.add(name);
    final failure = failWith;
    failWith = null;
    if (failure != null) throw AuthException(failure);
    then?.call();
  }

  @override
  Stream<User?> userChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  User? get currentUser => _user;

  @override
  Future<void> signInWithGoogle() => _call(
    'google',
    () => _setUser(FakeUser(uid: 'u-google', displayName: 'Google Ali')),
  );

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _call(
    'signIn:$email',
    () => _setUser(FakeUser(uid: 'u-email', email: email)),
  );

  @override
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _call(
    'signUp:$name:$email',
    () => _setUser(FakeUser(uid: 'u-new', displayName: name, email: email)),
  );

  @override
  Future<void> sendPasswordResetEmail(String email) => _call('reset:$email');

  @override
  Future<void> updateDisplayName(String name) => _call('name:$name');

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) => _call('password');

  @override
  Future<void> signOut() => _call('signOut', () => _setUser(null));
}

/// The real app (router, theme, screens) on an in-memory Firestore and
/// [FakeAuth]. Returns the router so a test can open any screen.
Future<GoRouter> pumpSettle(
  WidgetTester tester, {
  required FakeFirebaseFirestore db,
  required FakeAuth auth,
  String? location,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: const SettleApp(),
    ),
  );
  final router = ProviderScope.containerOf(
    tester.element(find.byType(SettleApp)),
  ).read(appRouterProvider);
  if (location != null) router.go(location);
  await settle(tester);
  return router;
}

/// Lets streams deliver and the screen rebuild. Not pumpAndSettle: a
/// progress indicator would keep that waiting for ever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  // Sheets and page transitions run up to 300 ms.
  await tester.pump(const Duration(milliseconds: 400));
}

/// Taps [finder] (scrolling it into view first) and lets the screen settle.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await settle(tester);
}

/// Runs [body] on the real clock. Widget tests run on a fake one, so
/// awaiting a Firestore stream (or a write) in the test itself would wait
/// for ever; use this to seed or read data from inside a widget test.
Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async =>
    (await tester.runAsync(body)) as T;
