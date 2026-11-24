import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/l10n/app_localizations_en.dart';

import '../helpers/test_app.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('signed out, the app opens on Sign in', (tester) async {
    await pumpSettle(tester, db: FakeFirebaseFirestore(), auth: FakeAuth());
    expect(find.text(l10n.signInWithGoogle), findsOneWidget);
  });

  testWidgets('signed in with no groups, Home shows how it works', (
    tester,
  ) async {
    await pumpSettle(
      tester,
      db: FakeFirebaseFirestore(),
      auth: FakeAuth(
        user: FakeUser(uid: 'u1', displayName: 'Ali'),
      ),
    );
    expect(find.text(l10n.homeNoGroupsTitle), findsOneWidget);
  });
}
