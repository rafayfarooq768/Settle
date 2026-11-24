import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/auth/ui/auth_providers.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/features/groups/ui/join_screen.dart';
import 'package:settle/features/home/ui/home_screen.dart';
import 'package:settle/features/profile/ui/profile_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/l10n_delegates.dart';
import 'package:settle/l10n/app_localizations_en.dart';

Widget _app(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: appLocalizationsDelegates,
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
    expect(find.text(l10n.homeNoGroupsTitle), findsOneWidget);
    // The three steps of how Settle works.
    expect(find.text(l10n.homeStep1), findsOneWidget);
    expect(find.text(l10n.homeStep3), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.createGroupButton),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, l10n.joinWithCodeButton),
      findsOneWidget,
    );
  });

  // Owner, 2026-11-24: the example code took a second to appear.
  testWidgets('Join: the example code shows on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const JoinScreen(), [
        myIdentityProvider.overrideWithValue(
          const MyIdentity(uid: 'u1', name: 'Ali'),
        ),
      ]),
    );
    final hint = find.text(l10n.joinCodeHint);
    expect(hint, findsOneWidget);
    // Not faded out, waiting for focus and the label animation.
    final fade = tester.widgetList<AnimatedOpacity>(
      find.ancestor(of: hint, matching: find.byType(AnimatedOpacity)),
    );
    expect(fade.every((o) => o.opacity == 1), isTrue);
  });
}
