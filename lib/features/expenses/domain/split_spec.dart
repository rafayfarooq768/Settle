import '../../../core/firestore/firestore_fields.dart';
import '../../../core/money/money.dart';
import 'expense.dart';

/// What the person entered on the split screen (PLAN.md §4 Split modes).
/// It turns into shares with the money core; balances never see it.
/// Stored as `splitInput` so the expense can be edited in the same mode.
sealed class SplitSpec {
  const SplitSpec();

  /// Everyone ticked, split equally: the 3-tap default (PLAN.md §2).
  factory SplitSpec.everyone(Iterable<String> memberIds) =>
      EqualSpec(memberIds.toList());

  SplitMode get mode;

  /// Why it can't be saved yet, or null when it adds up.
  SplitProblem? problem(int? amount);

  /// Shares summing exactly to [amount]. [order] is the group's member
  /// order; leftover paisa go payer first. Throws [MoneyException] when
  /// [problem] isn't null.
  Map<String, int> shares({
    required int amount,
    required List<String> order,
    required Iterable<String> payers,
  });

  Json toJson();

  /// Reads `splitInput` back; null if it doesn't match [mode].
  static SplitSpec? fromJson(SplitMode mode, Json json) {
    Map<String, int>? ints(Object? raw) {
      if (raw is! Map) return null;
      final out = <String, int>{};
      for (final e in raw.entries) {
        if (e.key is! String || e.value is! int) return null;
        out[e.key as String] = e.value as int;
      }
      return out;
    }

    switch (mode) {
      case SplitMode.equal:
        final raw = json['participants'];
        if (raw is! List || raw.any((id) => id is! String)) return null;
        return EqualSpec(raw.cast<String>());
      case SplitMode.exact:
        final m = ints(json['amounts']);
        return m == null ? null : ExactSpec(m);
      case SplitMode.percent:
        final m = ints(json['basisPoints']);
        return m == null ? null : PercentSpec(m);
      case SplitMode.itemized:
        return ItemizedSpec.fromJson(json);
    }
  }
}

/// Why a split can't be saved, for the inline line under it.
sealed class SplitProblem {
  const SplitProblem();
}

class NobodyPicked extends SplitProblem {
  const NobodyPicked();
}

class AmountNeeded extends SplitProblem {
  const AmountNeeded();
}

/// Exact: [paisa] still to assign (negative = too much).
class RupeesLeft extends SplitProblem {
  const RupeesLeft(this.paisa);
  final int paisa;
}

/// Percent: [basisPoints] still to assign (negative = over 100%).
class PercentLeft extends SplitProblem {
  const PercentLeft(this.basisPoints);
  final int basisPoints;
}

/// Itemized: no items yet.
class NoItems extends SplitProblem {
  const NoItems();
}

/// Itemized: an item nobody had.
class ItemWithoutPeople extends SplitProblem {
  const ItemWithoutPeople();
}

/// Itemized: the amount was changed and no longer matches the bill.
class BillTotalDiffers extends SplitProblem {
  const BillTotalDiffers(this.total);
  final int total;
}

class EqualSpec extends SplitSpec {
  const EqualSpec(this.participants);

  final List<String> participants;

  @override
  SplitMode get mode => SplitMode.equal;

  @override
  SplitProblem? problem(int? amount) =>
      participants.isEmpty ? const NobodyPicked() : null;

  @override
  Map<String, int> shares({
    required int amount,
    required List<String> order,
    required Iterable<String> payers,
  }) => splitEqual(
    amount: amount,
    participants: [
      for (final id in order)
        if (participants.contains(id)) id,
    ],
    payers: payers,
  );

  @override
  Json toJson() => {'participants': participants};
}

class ExactSpec extends SplitSpec {
  const ExactSpec(this.amounts);

  /// memberId → paisa. Missing = 0.
  final Map<String, int> amounts;

  @override
  SplitMode get mode => SplitMode.exact;

  @override
  SplitProblem? problem(int? amount) {
    if (amount == null || amount == 0) return const AmountNeeded();
    final left = exactRemaining(amount: amount, amounts: amounts);
    if (left != 0) return RupeesLeft(left);
    return null;
  }

  @override
  Map<String, int> shares({
    required int amount,
    required List<String> order,
    required Iterable<String> payers,
  }) => splitExact(amount: amount, amounts: _nonZero(amounts));

  @override
  Json toJson() => {'amounts': _nonZero(amounts)};
}

class PercentSpec extends SplitSpec {
  const PercentSpec(this.basisPoints);

  /// memberId → basis points (10% = 1000). Missing = 0.
  final Map<String, int> basisPoints;

  @override
  SplitMode get mode => SplitMode.percent;

  @override
  SplitProblem? problem(int? amount) {
    final left = percentRemaining(basisPoints);
    return left == 0 ? null : PercentLeft(left);
  }

  @override
  Map<String, int> shares({
    required int amount,
    required List<String> order,
    required Iterable<String> payers,
  }) => _nonZero(
    splitPercent(
      amount: amount,
      basisPoints: _nonZero(basisPoints),
      order: order,
      payers: payers,
    ),
  );

  @override
  Json toJson() => {'basisPoints': _nonZero(basisPoints)};
}

/// People with nothing entered (or whose part rounds to 0 paisa) aren't
/// part of the expense, so they're left out ("not involved" in the list).
Map<String, int> _nonZero(Map<String, int> m) => {
  for (final e in m.entries)
    if (e.value != 0) e.key: e.value,
};

/// One line on the bill: [name] (may be empty), its price, who had it.
class BillLine {
  const BillLine({
    required this.name,
    required this.amount,
    required this.memberIds,
  });

  final String name;
  final int amount;
  final List<String> memberIds;

  Json toJson() => {'name': name, 'amount': amount, 'members': memberIds};
}

/// Itemized (PLAN.md §4): items → people, shared items split equally
/// between [sharedWith], plus tax and service charge as a percentage of
/// the items and a tip in rupees. Those are spread in proportion to what
/// each person had, or equally. The bill total becomes the expense amount.
class ItemizedSpec extends SplitSpec {
  const ItemizedSpec({
    required this.items,
    this.shared = const [],
    this.sharedWith = const [],
    this.taxBp = 0,
    this.serviceBp = 0,
    this.tip = 0,
    this.spread = ExtrasSpread.proportional,
  });

  /// Each person's own items (who had it is picked per item).
  final List<BillLine> items;

  /// Shared items (drinks, starters): each split equally between its own
  /// `memberIds` ("Who shared it?").
  final List<BillLine> shared;

  /// Fallback for a shared item with no `memberIds`: everyone who had an
  /// item, or the whole group (worked out by the screen).
  final List<String> sharedWith;

  List<String> _sharers(BillLine line) =>
      line.memberIds.isEmpty ? sharedWith : line.memberIds;
  final int taxBp;
  final int serviceBp;

  /// Paisa.
  final int tip;
  final ExtrasSpread spread;

  /// Personal and shared items together, before tax, service and tip.
  int get itemsTotal =>
      [...items, ...shared].fold(0, (sum, i) => sum + i.amount);

  int get tax => percentOf(amount: itemsTotal, basisPoints: taxBp);

  int get service => percentOf(amount: itemsTotal, basisPoints: serviceBp);

  int get extras => tax + service + tip;

  int get total => itemsTotal + extras;

  @override
  SplitMode get mode => SplitMode.itemized;

  @override
  SplitProblem? problem(int? amount) {
    if (items.isEmpty && shared.isEmpty) return const NoItems();
    if (items.any((i) => i.memberIds.isEmpty) ||
        shared.any((i) => _sharers(i).isEmpty)) {
      return const ItemWithoutPeople();
    }
    if (amount != null && amount != total) return BillTotalDiffers(total);
    return null;
  }

  @override
  Map<String, int> shares({
    required int amount,
    required List<String> order,
    required Iterable<String> payers,
  }) {
    if (amount != total) {
      throw const MoneyException('The amount must match the bill total.');
    }
    return _nonZero(
      splitItemized(
        items: [
          for (final i in items)
            BillItem(amount: i.amount, memberIds: i.memberIds),
          for (final i in shared)
            BillItem(amount: i.amount, memberIds: _sharers(i)),
        ],
        order: order,
        extras: extras,
        spread: spread,
        payers: payers,
      ),
    );
  }

  @override
  Json toJson() => {
    'items': [for (final i in items) i.toJson()],
    'shared': [for (final i in shared) i.toJson()],
    'sharedWith': sharedWith,
    'taxBp': taxBp,
    'serviceBp': serviceBp,
    'tip': tip,
    'spread': spread.name,
  };

  static ItemizedSpec? fromJson(Json json) {
    List<String>? ids(Object? raw) =>
        raw is List && raw.every((id) => id is String)
        ? raw.cast<String>()
        : null;
    List<BillLine>? lines(Object? raw) {
      if (raw is! List) return null;
      final out = <BillLine>[];
      for (final i in raw) {
        if (i is! Map) return null;
        final amount = i['amount'];
        final members = ids(i['members'] ?? const <String>[]);
        if (amount is! int || members == null) return null;
        out.add(
          BillLine(
            name: i['name'] is String ? i['name'] as String : '',
            amount: amount,
            memberIds: members,
          ),
        );
      }
      return out;
    }

    final items = lines(json['items']);
    final shared = lines(json['shared'] ?? const <Object>[]);
    final sharedWith = ids(json['sharedWith'] ?? const <String>[]);
    if (items == null || shared == null || sharedWith == null) return null;
    int intOf(String key) => json[key] is int ? json[key] as int : 0;
    return ItemizedSpec(
      items: items,
      shared: shared,
      sharedWith: sharedWith,
      taxBp: intOf('taxBp'),
      serviceBp: intOf('serviceBp'),
      tip: intOf('tip'),
      spread: json['spread'] == ExtrasSpread.equal.name
          ? ExtrasSpread.equal
          : ExtrasSpread.proportional,
    );
  }
}

/// Who shared items are split between: everyone who had one of [items],
/// in group [order]; the whole group when nobody did.
List<String> sharedWithFor(List<BillLine> items, List<String> order) {
  final had = {for (final i in items) ...i.memberIds};
  return had.isEmpty
      ? order
      : [
          for (final id in order)
            if (had.contains(id)) id,
        ];
}
