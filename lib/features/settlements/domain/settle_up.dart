import '../../../core/money/money.dart';

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
