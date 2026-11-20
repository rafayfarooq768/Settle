import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/core/widgets/loading_button.dart';
import 'package:settle/features/expenses/ui/payers_screen.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/l10n_delegates.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final joined = DateTime(2026, 11, 1);
  final ali = Member(id: 'm1', displayName: 'Ali', uid: 'u1', joinedAt: joined);
  final sara = Member(id: 'm2', displayName: 'Sara', joinedAt: joined);

  testWidgets('starts with you paying it all; Done only when it adds up', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider('g1')
              .overrideWith((ref) => Stream.value([ali, sara])),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PayersScreen(
            groupId: 'g1',
            args: PayersArgs(
              amount: 150000,
              meId: 'm1',
              payers: {'m1': 150000},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    bool done() =>
        tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed !=
        null;
    Finder input(int i) => find.byType(TextField).at(i);

    expect(find.text(l10n.payersTitleAmount('Rs 1,500')), findsOneWidget);
    expect(find.text('1,500'), findsOneWidget);
    expect(done(), isTrue);

    await tester.enterText(input(1), '500');
    await tester.pump();
    expect(find.text(l10n.splitTooMuch('Rs 500')), findsOneWidget);
    expect(done(), isFalse);

    await tester.enterText(input(0), '1000');
    await tester.pump();
    expect(find.text(l10n.splitAddsUp('Rs 1,500')), findsOneWidget);
    expect(done(), isTrue);
  });
}
