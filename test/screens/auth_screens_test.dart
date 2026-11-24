import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settle/features/auth/domain/auth_repository.dart';
import 'package:settle/l10n/app_localizations_en.dart';

import '../helpers/test_app.dart';

/// Sign in, sign up and reset password (PLAN.md §8 screens 1–2), on the
/// real router with a fake sign-in.
void main() {
  final l10n = AppLocalizationsEn();
  late FakeFirebaseFirestore db;
  late FakeAuth auth;

  setUp(() {
    db = FakeFirebaseFirestore();
    auth = FakeAuth();
  });

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder button(String label) => find.widgetWithText(FilledButton, label);

  group('Sign in', () {
    testWidgets('empty fields say what is missing, nothing is sent', (
      tester,
    ) async {
      await pumpSettle(tester, db: db, auth: auth);
      await tapAndSettle(tester, button(l10n.signInButton));
      expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
      expect(find.text(l10n.errorPasswordRequired), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('a wrong password is shown in plain words', (tester) async {
      await pumpSettle(tester, db: db, auth: auth);
      await tester.enterText(field(l10n.signInEmailLabel), 'ali@example.com');
      await tester.enterText(field(l10n.signInPasswordLabel), 'wrong1');
      auth.failWith = AuthFailure.wrongPassword;
      await tapAndSettle(tester, button(l10n.signInButton));
      expect(find.text(l10n.errorWrongPassword), findsOneWidget);
      expect(find.text(l10n.homeNoGroupsTitle), findsNothing);
    });

    testWidgets('no internet says so', (tester) async {
      await pumpSettle(tester, db: db, auth: auth);
      await tester.enterText(field(l10n.signInEmailLabel), 'ali@example.com');
      await tester.enterText(field(l10n.signInPasswordLabel), 'secret1');
      auth.failWith = AuthFailure.network;
      await tapAndSettle(tester, button(l10n.signInButton));
      expect(find.text(l10n.errorNetwork), findsOneWidget);
    });

    testWidgets('the right password opens Home and makes a profile', (
      tester,
    ) async {
      await pumpSettle(tester, db: db, auth: auth);
      await tester.enterText(
        field(l10n.signInEmailLabel),
        '  ali@example.com ',
      );
      await tester.enterText(field(l10n.signInPasswordLabel), 'secret1');
      await tapAndSettle(tester, button(l10n.signInButton));
      expect(auth.calls, ['signIn:ali@example.com']);
      expect(find.text(l10n.homeNoGroupsTitle), findsOneWidget);
      final profile = await db.doc('users/u-email').get();
      expect(profile.data()!['email'], 'ali@example.com');
    });

    testWidgets('Google sign-in opens Home', (tester) async {
      await pumpSettle(tester, db: db, auth: auth);
      await tapAndSettle(tester, find.text(l10n.signInWithGoogle));
      expect(auth.calls, ['google']);
      expect(find.text(l10n.homeNoGroupsTitle), findsOneWidget);
    });

    testWidgets('closing the Google chooser shows no error', (tester) async {
      await pumpSettle(tester, db: db, auth: auth);
      auth.failWith = AuthFailure.cancelled;
      await tapAndSettle(tester, find.text(l10n.signInWithGoogle));
      expect(find.text(l10n.errorGeneric), findsNothing);
      expect(find.text(l10n.signInWithGoogle), findsOneWidget);
    });
  });

  group('Sign up', () {
    Future<void> open(WidgetTester tester) async {
      await pumpSettle(tester, db: db, auth: auth);
      await tapAndSettle(
        tester,
        find.widgetWithText(TextButton, l10n.signUpButton),
      );
    }

    testWidgets('asks for a name, an email and a 6-character password', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(field(l10n.signInPasswordLabel), '12345');
      await tapAndSettle(tester, button(l10n.signUpButton));
      expect(find.text(l10n.errorNameRequired), findsOneWidget);
      expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
      expect(find.text(l10n.errorWeakPassword), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('a bad phone number is caught before signing up', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(field(l10n.signUpNameLabel), 'Sara');
      await tester.enterText(field(l10n.signInEmailLabel), 'sara@example.com');
      await tester.enterText(field(l10n.signInPasswordLabel), 'secret1');
      await tester.enterText(field(l10n.phoneLabel), '12');
      await tapAndSettle(tester, button(l10n.signUpButton));
      expect(find.text(l10n.errorInvalidPhone), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('an email already in use says so', (tester) async {
      await open(tester);
      await tester.enterText(field(l10n.signUpNameLabel), 'Sara');
      await tester.enterText(field(l10n.signInEmailLabel), 'sara@example.com');
      await tester.enterText(field(l10n.signInPasswordLabel), 'secret1');
      auth.failWith = AuthFailure.emailInUse;
      await tapAndSettle(tester, button(l10n.signUpButton));
      expect(find.text(l10n.errorEmailInUse), findsOneWidget);
    });

    testWidgets('signing up saves the name and phone on the profile', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(field(l10n.signUpNameLabel), ' Sara ');
      await tester.enterText(field(l10n.signInEmailLabel), 'sara@example.com');
      await tester.enterText(field(l10n.signInPasswordLabel), 'secret1');
      await tester.enterText(field(l10n.phoneLabel), '0333 1112222');
      await tapAndSettle(tester, button(l10n.signUpButton));
      expect(auth.calls, ['signUp:Sara:sara@example.com']);
      expect(find.text(l10n.homeNoGroupsTitle), findsOneWidget);
      final profile = (await db.doc('users/u-new').get()).data()!;
      expect(profile['displayName'], 'Sara');
      expect(profile['phone'], '+923331112222');
    });
  });

  group('Reset password', () {
    testWidgets('sends the link and says to check email and spam', (
      tester,
    ) async {
      await pumpSettle(tester, db: db, auth: auth, location: '/reset-password');
      await tester.enterText(field(l10n.signInEmailLabel), 'ali@example.com');
      await tapAndSettle(tester, button(l10n.resetPasswordButton));
      expect(auth.calls, ['reset:ali@example.com']);
      expect(find.text(l10n.resetPasswordCheckEmailTitle), findsOneWidget);
      expect(find.text(l10n.resetPasswordSpamHint), findsOneWidget);
    });

    testWidgets('a bad email is caught first', (tester) async {
      await pumpSettle(tester, db: db, auth: auth, location: '/reset-password');
      await tester.enterText(field(l10n.signInEmailLabel), 'ali@');
      await tapAndSettle(tester, button(l10n.resetPasswordButton));
      expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
      expect(auth.calls, isEmpty);
    });
  });
}
