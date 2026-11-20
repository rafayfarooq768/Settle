import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';
import 'package:settle/core/theme/app_theme.dart';
import 'package:settle/features/balances/domain/balance_rows.dart';
import 'package:settle/features/balances/ui/balances_providers.dart';
import 'package:settle/features/expenses/domain/expense.dart';
import 'package:settle/features/expenses/ui/expenses_providers.dart';
import 'package:settle/features/groups/domain/group.dart';
import 'package:settle/features/groups/ui/groups_providers.dart';
import 'package:settle/features/settlements/domain/settle_up.dart';
import 'package:settle/features/settlements/domain/settlement.dart';
import 'package:settle/features/settlements/ui/settle_up_tab.dart';
import 'package:settle/features/settlements/ui/settlements_providers.dart';
import 'package:settle/l10n/app_localizations.dart';
import 'package:settle/l10n/l10n_delegates.dart';
import 'package:settle/l10n/app_localizations_en.dart';

final _t = DateTime(2026, 11, 20);

Member _m(String id, String name, {bool active = true}) => Member(
  id: id,
  displayName: name,
  uid: 'u$id',
  joinedAt: _t,
  active: active,
);

Expense _e(
  String id,
  int amount,
  Map<String, int> payers,
  Map<String, int> shares, {
  bool deleted = false,
}) => Expense(
  id: id,
  title: id,
  amount: amount,
  date: _t,
  createdBy: 'u',
  createdAt: _t,
  updatedAt: _t,
  splitMode: SplitMode.equal,
  payers: payers,
  shares: shares,
  deleted: deleted,
);

Settlement _s(String from, String to, int amount, SettlementStatus status) =>
    Settlement(
      id: '$from$to$amount',
      from: from,
      to: to,
      amount: amount,
      status: status,
      createdBy: 'u',
      createdAt: _t,
    );

// PLAN.md §2 chai scene: A paid 1000, B paid 500, 5 people.
const _chaiNets = {
  'a': 70000,
  'b': 20000,
  'c': -30000,
  'd': -30000,
  'e': -30000,
};

void main() {
  group('settleUpList', () {
    test('your rows come first, the rest keep the simplify order', () {
      final list = settleUpList(
        _chaiNets,
        meId: 'e',
        order: const ['a', 'b', 'c', 'd', 'e'],
      );
      expect(list.mine, [
        const Transfer(from: 'e', to: 'b', amount: 20000),
        const Transfer(from: 'e', to: 'a', amount: 10000),
      ]);
      expect(list.others, [
        const Transfer(from: 'c', to: 'a', amount: 30000),
        const Transfer(from: 'd', to: 'a', amount: 30000),
      ]);
    });

    test('all zero is empty', () {
      expect(settleUpList({'a': 0, 'b': 0}, meId: 'a').isEmpty, isTrue);
    });
  });

  test('balanceRows: owed first, owes last, removed placeholders only '
      'while they have a balance', () {
    final rows = balanceRows(
      [
        _m('a', 'Ali'),
        _m('b', 'Sara'),
        _m('c', 'Bilal'),
        _m('x', 'Gone', active: false),
        _m('y', 'Gone but owes', active: false),
      ],
      {'a': -100, 'b': 300, 'c': 0, 'x': 0, 'y': -200},
    );
    expect([for (final m in rows) m.id], ['b', 'c', 'a', 'y']);
  });

  test('groupNetsProvider counts only live, balanced expenses and '
      'confirmed settlements', () async {
    final container = ProviderContainer(
      overrides: [
        membersProvider('g').overrideWith(
          (ref) => Stream.value([_m('a', 'Ali'), _m('b', 'Sara')]),
        ),
        expensesProvider('g').overrideWith(
          (ref) => Stream.value([
            _e('ok', 1000, {'a': 1000}, {'a': 500, 'b': 500}),
            _e('deleted', 800, {'a': 800}, {'b': 800}, deleted: true),
            // Shares add up to 900, not 1000: left out, not crashing.
            _e('broken', 1000, {'a': 1000}, {'b': 900}),
          ]),
        ),
        settlementsProvider('g').overrideWith(
          (ref) => Stream.value([
            _s('b', 'a', 200, SettlementStatus.confirmed),
            _s('b', 'a', 300, SettlementStatus.pending),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(groupNetsProvider('g'), (_, _) {});
    addTearDown(sub.close);
    await container.read(membersProvider('g').future);
    await container.read(expensesProvider('g').future);
    await container.read(settlementsProvider('g').future);

    expect(container.read(groupNetsProvider('g')).requireValue, {
      'a': 300,
      'b': -300,
    });
  });

  test('pendingForMe: to confirm when paid to you, waiting when you paid', () {
    final p = pendingForMe([
      _s('b', 'a', 300, SettlementStatus.pending),
      _s('a', 'c', 200, SettlementStatus.pending),
      _s('b', 'a', 100, SettlementStatus.confirmed),
      _s('b', 'c', 50, SettlementStatus.pending),
    ], 'a');
    expect([for (final s in p.toConfirm) s.amount], [300]);
    expect([for (final s in p.waiting) s.amount], [200]);
  });

  final chai = Group(
    id: 'g',
    name: 'Chai',
    type: 'Friends',
    createdBy: 'ua',
    createdAt: _t,
    joinCode: 'CHAI-4821',
    memberUids: const ['ua', 'ub', 'uc', 'ud', 'ue'],
  );
  final members = [
    _m('a', 'Ali'),
    _m('b', 'Sara'),
    _m('c', 'Bilal'),
    _m('d', 'Hamza'),
    _m('e', 'Fatima'),
  ];

  Future<void> openTab(
    WidgetTester tester, {
    required Member me,
    List<Settlement> settlements = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider('g').overrideWith((ref) => Stream.value(members)),
          settlementsProvider('g')
              .overrideWith((ref) => Stream.value(settlements)),
          groupNetsProvider('g').overrideWithValue(const AsyncData(_chaiNets)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettleUpTab(group: chai, me: me),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Settle up tab: money lines say who, direction and amount', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    await openTab(tester, me: members[0]);

    expect(find.text(l10n.settleYoursLabel), findsOneWidget);
    expect(find.text(l10n.transferPaysYou('Bilal')), findsOneWidget);
    expect(find.text(l10n.transferPaysYou('Hamza')), findsOneWidget);
    expect(find.text(l10n.transferPaysYou('Fatima')), findsOneWidget);
    expect(find.text(l10n.settleOthersLabel), findsOneWidget);
    expect(find.text(l10n.transferPays('Fatima', 'Sara')), findsOneWidget);
    expect(find.text('Rs 300'), findsNWidgets(2));
    expect(find.text('Rs 200'), findsOneWidget);
    expect(find.text('Rs 100'), findsOneWidget);
    // Ali is owed by three people: Record + Remind on each, nothing on
    // the row between others.
    expect(find.text(l10n.recordPaymentButton), findsNWidgets(3));
    expect(find.text(l10n.remindButton), findsNWidgets(3));
    expect(find.text(l10n.iPaidButton), findsNothing);
  });

  testWidgets('Settle up tab: debtor sees I paid; pending shows on both '
      'sides', (tester) async {
    final l10n = AppLocalizationsEn();
    final pending = _s('e', 'a', 10000, SettlementStatus.pending);

    await openTab(tester, me: members[4], settlements: [pending]);
    expect(find.text(l10n.transferYouPay('Sara')), findsOneWidget);
    // Already waiting on Ali: only Sara's row offers I paid.
    expect(find.text(l10n.iPaidButton), findsOneWidget);
    // The waiting payment sits in Ali's own row, not a row of its own.
    expect(find.text(l10n.transferYouPay('Ali')), findsOneWidget);
    expect(find.text(l10n.pendingYouPaid('Ali')), findsNothing);
    expect(
      find.text(l10n.pendingWaitingAmount('Ali', 'Rs 100')),
      findsOneWidget,
    );
    expect(find.text(l10n.cancelPaymentButton), findsOneWidget);

    await openTab(tester, me: members[0], settlements: [pending]);
    // Fatima's row swaps Record / Remind for Confirm / Not received.
    expect(find.text(l10n.transferPaysYou('Fatima')), findsOneWidget);
    expect(find.text(l10n.pendingSaysPaidAmount('Rs 100')), findsOneWidget);
    expect(find.text(l10n.confirmButton), findsOneWidget);
    expect(find.text(l10n.notReceivedButton), findsOneWidget);
    expect(find.text(l10n.recordPaymentButton), findsNWidgets(2));
    expect(find.text(l10n.remindButton), findsNWidgets(2));
  });
}
