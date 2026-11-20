import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/split_spec.dart';

/// "Rs 200 left to assign", "10% too much", "Enter the amount first."
String splitProblemText(AppLocalizations l10n, SplitProblem problem) =>
    switch (problem) {
      NobodyPicked() => l10n.errorPickSomeone,
      AmountNeeded() => l10n.splitAmountFirst,
      RupeesLeft(:final paisa) =>
        paisa > 0
            ? l10n.splitLeftToAssign(formatRupees(paisa))
            : l10n.splitTooMuch(formatRupees(-paisa)),
      PercentLeft(:final basisPoints) =>
        basisPoints > 0
            ? l10n.splitLeftToAssign(formatPercent(basisPoints))
            : l10n.splitTooMuch(formatPercent(-basisPoints)),
      NoItems() => l10n.errorItemsNeeded,
      ItemWithoutPeople() => l10n.errorItemNeedsPeople,
      BillTotalDiffers(:final total) => l10n.billAddsUpTo(formatRupees(total)),
    };

/// The line when it adds up: "Rs 200 each", "Adds up to Rs 1,000",
/// "Adds up to 100%", "6 shares".
String splitStatusText(AppLocalizations l10n, SplitSpec spec, int? amount) =>
    switch (spec) {
      EqualSpec(:final participants) =>
        amount != null && amount > 0
            ? l10n.splitEach(formatRupees(amount ~/ participants.length))
            : l10n.splitEqually(participants.length),
      ExactSpec() => l10n.splitAddsUp(formatRupees(amount ?? 0)),
      PercentSpec() => l10n.splitAddsUp(formatPercent(fullPercentBp)),
      SharesSpec(:final units) => l10n.splitSharesCount(sumOf(units)),
      ItemizedSpec(:final total) => l10n.billTotal(formatRupees(total)),
    };
