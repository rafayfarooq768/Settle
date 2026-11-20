import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/auth/ui/auth_providers.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/features/groups/ui/join_screen.dart';
import 'package:settle/features/home/ui/home_screen.dart';
import 'package:settle/features/profile/ui/profile_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/app_localizations_en.dart';

Widget _app(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('Join: a malformed code shows an inline error, no network call', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const JoinScreen(), [
        myIdentityProvider.overrideWithValue(
          const MyIdentity(uid: 'u1', name: 'Ali'),
        ),
      ]),
    );
    await tester.enterText(find.byType(TextField), 'chai');
    await tester.tap(find.text(l10n.joinButton));
    await tester.pump();
    expect(find.text(l10n.errorCodeFormat), findsOneWidget);
  });

  testWidgets('Home: no groups shows the empty state with both actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HomeScreen(), [
        userChangesProvider.overrideWith((ref) => Stream.value(null)),
        myGroupsProvider.overrideWith((ref) => Stream.value(const [])),
      ]),
    );
    await tester.pump();
    expect(find.text(l10n.homeNoGroups), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.createGroupButton),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, l10n.joinWithCodeButton),
      findsOneWidget,
    );
  });
}
