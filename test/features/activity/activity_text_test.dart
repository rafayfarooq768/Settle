import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/activity/domain/activity.dart';
import 'package:settle/features/activity/ui/activity_text.dart';
import 'package:settle/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const names = {'me': 'Rafay', 'ali': 'Ali', 'sara': 'Sara'};

  ({String text, String? detail}) line(Activity a) =>
      activityText(l10n, a, names: names, meId: 'me');

  Activity entry(
    ActivityType type, {
    String actor = 'ali',
    String summary = '',
    Map<String, Object?>? before,
    Map<String, Object?>? after,
  }) => Activity(
    id: 'a',
    type: type,
    actorMemberId: actor,
    createdAt: DateTime(2026, 11, 20),
    summary: summary,
    before: before,
    after: after,
  );

  test('expense added: who, what and the amount', () {
    final r = line(
      entry(
        ActivityType.expenseAdded,
        summary: 'Chai',
        after: {'amount': 100000},
      ),
    );
    expect(r.text, 'Ali added Chai');
    expect(r.detail, 'Rs 1,000');
  });

  test('you are "You"', () {
    expect(
      line(entry(ActivityType.expenseDeleted, actor: 'me', summary: 'Chai'))
          .text,
      'You deleted Chai',
    );
  });

  test('an edit shows the amount change, or a plain note', () {
    final changed = line(
      entry(
        ActivityType.expenseEdited,
        summary: 'Chai',
        before: {'amount': 100000},
        after: {'amount': 120000},
      ),
    );
    expect(changed.detail, 'Rs 1,000 → Rs 1,200');
    final same = line(
      entry(
        ActivityType.expenseEdited,
        summary: 'Chai',
        before: {'amount': 100000},
        after: {'amount': 100000},
      ),
    );
    expect(same.detail, 'Details changed');
  });

  test('payments: sent, recorded, cancelled, not received', () {
    final pay = {'from': 'ali', 'to': 'me', 'amount': 30000};
    expect(
      line(
        entry(
          ActivityType.settlementRecorded,
          after: {...pay, 'status': 'pending'},
        ),
      ).text,
      'Ali said they sent a payment',
    );
    final recorded = line(
      entry(
        ActivityType.settlementRecorded,
        actor: 'me',
        after: {...pay, 'status': 'confirmed'},
      ),
    );
    expect(recorded.text, 'You recorded a payment');
    expect(recorded.detail, 'Ali paid you Rs 300');
    // The payer took back their own "I paid".
    expect(
      line(
        entry(
          ActivityType.settlementDeleted,
          before: {...pay, 'status': 'pending'},
        ),
      ).text,
      'Ali cancelled a payment',
    );
    // The person paid said it never arrived.
    expect(
      line(
        entry(
          ActivityType.settlementDeleted,
          actor: 'me',
          before: {...pay, 'status': 'pending'},
        ),
      ).text,
      'You said a payment was not received',
    );
  });

  test('someone no longer in the list', () {
    expect(
      line(entry(ActivityType.memberLeft, actor: 'gone')).text,
      'Someone left',
    );
  });
}
