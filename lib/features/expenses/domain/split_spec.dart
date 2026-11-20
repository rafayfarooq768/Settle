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
      case SplitMode.shares:
        final m = ints(json['units']);
        return m == null ? null : SharesSpec(m);
      case SplitMode.itemized:
        return null;
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

class SharesSpec extends SplitSpec {
  const SharesSpec(this.units);

  /// memberId → units (e.g. nights). Missing = 0.
  final Map<String, int> units;

  @override
  SplitMode get mode => SplitMode.shares;

  @override
  SplitProblem? problem(int? amount) =>
      sumOf(units) < 1 ? const NobodyPicked() : null;

  @override
  Map<String, int> shares({
    required int amount,
    required List<String> order,
    required Iterable<String> payers,
  }) => _nonZero(
    splitShares(
      amount: amount,
      units: _nonZero(units),
      order: order,
      payers: payers,
    ),
  );

  @override
  Json toJson() => {'units': _nonZero(units)};
}

/// People with nothing entered (or whose part rounds to 0 paisa) aren't
/// part of the expense, so they're left out ("not involved" in the list).
Map<String, int> _nonZero(Map<String, int> m) => {
  for (final e in m.entries)
    if (e.value != 0) e.key: e.value,
};
