import '../../../core/money/money.dart';
import 'settlement.dart';

/// The settle-up list split for display (DESIGN.md §11): payments that
/// involve you first, then everyone else's. Both keep the simplify order,
/// so every phone shows the same list.
class SettleUpList {
  const SettleUpList({required this.mine, required this.others});

  final List<Transfer> mine;
  final List<Transfer> others;

  bool get isEmpty => mine.isEmpty && others.isEmpty;
}

/// Simplified payments for a group's [nets] (PLAN.md §4), with [meId]'s
/// rows pulled to the top. [order] is the group's member order.
SettleUpList settleUpList(
  Map<String, int> nets, {
  required String meId,
  List<String> order = const [],
}) {
  final transfers = simplifyDebts(nets, order: order);
  bool involvesMe(Transfer t) => t.from == meId || t.to == meId;
  return SettleUpList(
    mine: [
      for (final t in transfers)
        if (involvesMe(t)) t,
    ],
    others: [
      for (final t in transfers)
        if (!involvesMe(t)) t,
    ],
  );
}

/// Pending "I paid"s that involve you (PLAN.md §3 item 10). They don't
/// change balances until confirmed, so they're shown apart from the list.
class PendingForMe {
  const PendingForMe({required this.toConfirm, required this.waiting});

  /// Someone says they paid you: you confirm or say not received.
  final List<Settlement> toConfirm;

  /// You said you paid: waiting for them to confirm.
  final List<Settlement> waiting;

  bool get isEmpty => toConfirm.isEmpty && waiting.isEmpty;
}

PendingForMe pendingForMe(Iterable<Settlement> settlements, String meId) {
  final pending = [
    for (final s in settlements)
      if (s.status == SettlementStatus.pending) s,
  ];
  return PendingForMe(
    toConfirm: [
      for (final s in pending)
        if (s.to == meId) s,
    ],
    waiting: [
      for (final s in pending)
        if (s.from == meId) s,
    ],
  );
}
