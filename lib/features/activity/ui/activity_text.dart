import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/activity.dart';

/// The sentence for one activity entry ("Ali added Chai") and an optional
/// muted detail line ("Rs 1,000 → Rs 1,200"). Built from the stored type
/// and data, never from stored English (CLAUDE.md: strings in ARB files).
/// [names] maps memberId → display name, including removed placeholders.
({String text, String? detail}) activityText(
  AppLocalizations l10n,
  Activity a, {
  required Map<String, String> names,
  required String meId,
}) {
  String name(String? id) =>
      id == meId ? l10n.youLabel : names[id] ?? l10n.activitySomeone;
  final actor = name(a.actorMemberId);
  final s = a.summary;

  String? amountOf(Map<String, Object?>? m) {
    final v = m?['amount'];
    return v is int ? formatRupees(v) : null;
  }

  // "Ali paid you Rs 300": who paid whom, from the stored ids.
  String? paymentLine(Map<String, Object?>? m) {
    final amount = amountOf(m);
    final from = m?['from'], to = m?['to'];
    if (amount == null || from is! String || to is! String) return null;
    // "you" mid-sentence, "You" at the start.
    final toName = to == meId ? l10n.youLabel.toLowerCase() : name(to);
    return l10n.activityPaymentLine(name(from), toName, amount);
  }

  return switch (a.type) {
    ActivityType.groupCreated => (
      text: l10n.activityGroupCreated(actor),
      detail: null,
    ),
    ActivityType.groupRenamed => (
      text: l10n.activityGroupRenamed(actor, s),
      detail: null,
    ),
    ActivityType.joinCodeRegenerated => (
      text: l10n.activityJoinCodeRegenerated(actor),
      detail: null,
    ),
    ActivityType.placeholderAdded => (
      text: l10n.activityPlaceholderAdded(actor, s),
      detail: null,
    ),
    ActivityType.memberRenamed => (
      text: l10n.activityMemberRenamed(actor, s),
      detail: null,
    ),
    ActivityType.placeholderRemoved => (
      text: l10n.activityPlaceholderRemoved(actor, s),
      detail: null,
    ),
    ActivityType.memberJoined => (
      text: l10n.activityMemberJoined(actor),
      detail: null,
    ),
    ActivityType.placeholderClaimed => (
      text: l10n.activityPlaceholderClaimed(actor, s),
      detail: null,
    ),
    ActivityType.memberLeft => (
      text: l10n.activityMemberLeft(actor),
      detail: null,
    ),
    ActivityType.expenseAdded => (
      text: l10n.activityExpenseAdded(actor, s),
      detail: amountOf(a.after),
    ),
    ActivityType.expenseEdited => (
      text: l10n.activityExpenseEdited(actor, s),
      detail: _editDetail(l10n, a),
    ),
    ActivityType.expenseDeleted => (
      text: l10n.activityExpenseDeleted(actor, s),
      detail: amountOf(a.before),
    ),
    ActivityType.expenseRestored => (
      text: l10n.activityExpenseRestored(actor, s),
      detail: null,
    ),
    ActivityType.settlementRecorded => (
      text: a.after?['status'] == 'pending'
          ? l10n.activityPaymentSent(actor)
          : l10n.activityPaymentRecorded(actor),
      detail: paymentLine(a.after),
    ),
    ActivityType.settlementConfirmed => (
      text: l10n.activityPaymentConfirmed(actor),
      detail: null,
    ),
    ActivityType.settlementDeleted => (
      text: switch ((a.before?['status'], a.before?['from'])) {
        // The payer took back their own "I paid".
        ('pending', final from) when from == a.actorMemberId =>
          l10n.activityPaymentCancelled(actor),
        // The person paid said it never arrived.
        ('pending', _) => l10n.activityPaymentNotReceived(actor),
        _ => l10n.activityPaymentRemoved(actor),
      },
      detail: paymentLine(a.before),
    ),
  };
}

/// "Rs 1,000 → Rs 1,200" when the amount changed, otherwise a plain note.
String? _editDetail(AppLocalizations l10n, Activity a) {
  final before = a.before?['amount'], after = a.after?['amount'];
  if (before is int && after is int && before != after) {
    return l10n.activityAmountChanged(
      formatRupees(before),
      formatRupees(after),
    );
  }
  return l10n.activityDetailsChanged;
}

/// Entries about an expense open its detail screen.
bool isExpenseActivity(ActivityType t) => switch (t) {
  ActivityType.expenseAdded ||
  ActivityType.expenseEdited ||
  ActivityType.expenseDeleted ||
  ActivityType.expenseRestored => true,
  _ => false,
};
