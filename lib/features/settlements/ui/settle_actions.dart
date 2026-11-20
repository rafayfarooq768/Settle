import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../profile/ui/profile_providers.dart';
import '../domain/settlement.dart';
import '../../profile/domain/payment_methods.dart';
import 'payment_sheet.dart';
import 'remind_sheet.dart';
import 'settlements_providers.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// The settle flow (PLAN.md §3 items 10–11). Writes go through
/// [SettlementRepository]; the security rules decide who may do what.
/// Undo over confirmation (DESIGN.md §8).
class SettleActions {
  SettleActions(
    this.context,
    this.ref, {
    required this.group,
    required this.me,
  });

  final BuildContext context;
  final WidgetRef ref;
  final Group group;
  final Member me;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// "I paid" [to]. Pending until they confirm; a placeholder can't
  /// confirm, so paying one counts straight away.
  Future<void> pay({required Member to, required int owed}) async {
    final l10n = _l10n;
    final amount = await showPaymentSheet(
      context,
      title: l10n.payTitle(to.displayName),
      hint: l10n.balanceYouOweName(to.displayName, formatRupees(owed)),
      action: l10n.iPaidButton,
      initial: owed,
      // Placeholders can't add methods, so there's nothing to show or ask.
      methods: to.isPlaceholder
          ? null
          : (
              list: forPaying(to.paymentMethods),
              label: l10n.payMethodsLabel(to.displayName),
              emptyText: l10n.payNoMethods(to.displayName),
            ),
    );
    if (amount == null) return;
    final confirmed = to.isPlaceholder;
    await _record(
      from: me.id,
      to: to.id,
      amount: amount,
      confirmed: confirmed,
      done: confirmed
          ? l10n.paymentRecorded
          : l10n.paymentSentToConfirm(to.displayName),
    );
  }

  /// The person paid records money they got. Counts straight away.
  Future<void> record({required Member from, required int owed}) async {
    final l10n = _l10n;
    final amount = await showPaymentSheet(
      context,
      title: l10n.recordTitle(from.displayName),
      hint: l10n.balanceNameOwesYou(from.displayName, formatRupees(owed)),
      action: l10n.recordPaymentButton,
      initial: owed,
    );
    if (amount == null) return;
    await _record(
      from: from.id,
      to: me.id,
      amount: amount,
      confirmed: true,
      done: l10n.paymentRecorded,
    );
  }

  Future<void> remind({required Member who, required int owed}) =>
      showRemindSheet(
        context,
        title: _l10n.remindTitle(who.displayName),
        message: _l10n.remindMessage(formatRupees(owed), group.name),
        phone: who.phone,
      );

  Future<void> confirm(Settlement s) => _run(
    () => ref
        .read(settlementRepositoryProvider)
        .confirm(groupId: group.id, actorMemberId: me.id, settlement: s),
    done: _l10n.paymentConfirmed,
  );

  /// "Not received" (the person paid) or "Cancel" (the payer).
  Future<void> remove(Settlement s, {required String done}) => _run(
    () => ref
        .read(settlementRepositoryProvider)
        .remove(groupId: group.id, actorMemberId: me.id, settlement: s),
    done: done,
  );

  Future<void> _record({
    required String from,
    required String to,
    required int amount,
    required bool confirmed,
    required String done,
  }) async {
    final identity = ref.read(myIdentityProvider);
    if (identity == null) return;
    final repo = ref.read(settlementRepositoryProvider);
    String? id;
    await _run(
      () async => id = await repo.record(
        groupId: group.id,
        uid: identity.uid,
        actorMemberId: me.id,
        from: from,
        to: to,
        amount: amount,
        confirmed: confirmed,
      ),
      done: done,
      undo: () {
        final recorded = id;
        if (recorded == null) return;
        repo.remove(
          groupId: group.id,
          actorMemberId: me.id,
          settlement: Settlement(
            id: recorded,
            from: from,
            to: to,
            amount: amount,
            status: confirmed
                ? SettlementStatus.confirmed
                : SettlementStatus.pending,
            createdBy: identity.uid,
            createdAt: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _run(
    Future<void> Function() write, {
    required String done,
    VoidCallback? undo,
  }) async {
    final l10n = _l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await write();
      messenger.showMessage(done, undoLabel: l10n.undoButton, onUndo: undo);
    } catch (e) {
      messenger.showMessage(errorText(l10n, e));
    }
  }
}
