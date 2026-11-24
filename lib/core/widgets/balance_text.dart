import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../money/money.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Who the balance belongs to, which decides the words.
enum BalanceWording {
  /// "You owe" / "You are owed" (your own balance)
  you,

  /// "Owes" / "Gets back" (someone else's, after their name)
  member,
}

/// The money label at the end of a row, the same everywhere (owner
/// 2026-11-20, polish): a short sentence-case word in the money colour over
/// the amount in bodyLarge 16/600 with tabular figures. States with no
/// amount ("Settled up", "Not involved") are one quiet line.
/// DESIGN.md §2: the words always say the direction, never colour alone.
class MoneyStack extends StatelessWidget {
  const MoneyStack({
    super.key,
    required this.label,
    required this.color,
    this.amount,
  });

  final String label;
  final Color color;

  /// Paisa, shown without a sign; null for a one-line state.
  final int? amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (amount == null) {
      return Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      );
    }
    // A list row gives its end a fixed height; at a very large font size
    // the two lines shrink together to fit it rather than the amount being
    // cut off at the bottom.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            formatRupees(amount!.abs()),
            style: rowAmountStyle(theme, color: color),
          ),
        ],
      ),
    );
  }
}

/// The amount at the end of any row: bodyLarge 16/600, tabular
/// (DESIGN (3).md §4). [MoneyStack] uses it too, so every row amount matches.
TextStyle? rowAmountStyle(ThemeData theme, {Color? color}) =>
    theme.textTheme.bodyLarge?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// A net balance in a list row (Home group rows, Balances).
class BalanceStack extends StatelessWidget {
  const BalanceStack({
    super.key,
    required this.net,
    this.wording = BalanceWording.you,
  });

  final int net;
  final BalanceWording wording;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final money = context.moneyColors;
    if (net == 0) {
      return MoneyStack(
        label: l10n.rowSettled,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    final owed = net > 0;
    return MoneyStack(
      label: switch ((owed, wording)) {
        (true, BalanceWording.you) => l10n.stackYouAreOwed,
        (false, BalanceWording.you) => l10n.stackYouOwe,
        (true, _) => l10n.stackIsOwed,
        (false, _) => l10n.stackOwes,
      },
      amount: net,
      color: owed ? money.owed : money.owe,
    );
  }
}

/// A big amount with a small "Rs" (DESIGN (3).md §3, polish 2026-11-20):
/// "Rs" about 60% of the number's size, weight 600, muted, on the number's
/// baseline, so the number carries the weight.
class BigAmount extends StatelessWidget {
  const BigAmount({
    super.key,
    required this.paisa,
    required this.style,
    this.color,
  });

  final int paisa;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final number = style?.copyWith(color: color);
    final size = number?.fontSize ?? 28;
    // "Rs 1,200" → "1,200": the number part only.
    final digits = formatRupees(paisa.abs())
        .substring(l10n.currencyPrefix.length);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.currencyPrefix,
            style: number?.copyWith(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(text: digits, style: number),
        ],
      ),
      // Amounts read left to right in Urdu too.
      textDirection: TextDirection.ltr,
    );
  }
}

/// The big balance (owner 2026-11-20; DESIGN (3).md polish): the words
/// over the amount, number first. Home uses headlineMedium, the Group
/// header headlineLarge ([large]). Settled is [settledLabel] over the
/// settled message in the brand settled colour.
class BalanceHero extends StatelessWidget {
  const BalanceHero({
    super.key,
    required this.net,
    this.large = true,
    this.settledLabel,
    this.settledText,
  });

  /// Null while the balance is still loading: the space is kept, empty,
  /// so nothing jumps when it arrives. Never shown as 0 ("settled") or as
  /// a part of the total: a wrong balance is worse than none for a moment.
  final int? net;
  final bool large;

  /// Defaults to "Your balance" / "All settled".
  final String? settledLabel;
  final String? settledText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    final big = large
        ? theme.textTheme.headlineLarge
        : theme.textTheme.headlineMedium;
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final net = this.net;
    if (net == null) {
      // The height of the amount layout, invisible and silent.
      return ExcludeSemantics(
        child: Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: BalanceHero(net: 1, large: large),
        ),
      );
    }
    if (net == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settledLabel ?? l10n.heroYourBalance,
            style: labelStyle?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Settled isn't a number: the title style, not the big one.
          Text(
            settledText ?? l10n.heroAllSettled,
            style: theme.textTheme.titleLarge?.copyWith(
              color: context.extraColors.settled,
            ),
          ),
        ],
      );
    }
    final color = net > 0 ? money.owed : money.owe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          net > 0 ? l10n.heroYouAreOwed : l10n.heroYouOwe,
          style: labelStyle?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        BigAmount(paisa: net, style: big, color: color),
      ],
    );
  }
}
