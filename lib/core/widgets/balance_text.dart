import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../money/money.dart';
import '../theme/app_theme_extensions.dart';

/// Who the balance belongs to, which decides the words.
enum BalanceWording {
  /// "you owe Rs 300" / "you are owed Rs 700" / "settled up"
  you,

  /// "owes Rs 300" / "is owed Rs 700" / "settled up" (after a name)
  member,
}

/// A net balance in words + colour (DESIGN.md §2: never colour alone;
/// owe/owed colours only for money). Tabular figures come from the theme.
class BalanceText extends StatelessWidget {
  const BalanceText({
    super.key,
    required this.net,
    this.wording = BalanceWording.you,
    this.style,
  });

  final int net;
  final BalanceWording wording;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    final amount = formatRupees(net);
    final (text, color) = switch ((net.sign, wording)) {
      (0, _) => (l10n.rowSettled, theme.colorScheme.onSurfaceVariant),
      (> 0, BalanceWording.you) => (l10n.rowYouAreOwed(amount), money.owed),
      (_, BalanceWording.you) => (l10n.rowYouOwe(amount), money.owe),
      (> 0, _) => (l10n.memberIsOwed(amount), money.owed),
      _ => (l10n.memberOwes(amount), money.owe),
    };
    return Text(
      text,
      style: (style ?? theme.textTheme.bodyMedium)?.copyWith(color: color),
    );
  }
}

/// The big one-line balance (Home summary, Group header): "You owe Rs 300",
/// "You are owed Rs 900", or the settled message in brand teal.
class BalanceHeadline extends StatelessWidget {
  const BalanceHeadline({
    super.key,
    required this.net,
    required this.settled,
    this.settledAccent = false,
  });

  final int net;

  /// Text shown when [net] is 0.
  final String settled;

  /// Use the brand "settled" colour (DESIGN.md §9: once per screen).
  final bool settledAccent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    final amount = formatRupees(net);
    // Settled isn't a number, so it doesn't get the big number style.
    if (net == 0) {
      return Text(
        settled,
        style: theme.textTheme.titleLarge?.copyWith(
          color: settledAccent ? context.extraColors.settled : null,
        ),
      );
    }
    final (text, color) = net > 0
        ? (l10n.balanceYouAreOwed(amount), money.owed)
        : (l10n.balanceYouOwe(amount), money.owe);
    return Text(
      text,
      style: theme.textTheme.headlineMedium?.copyWith(color: color),
    );
  }
}

/// Your balance in a list row, stacked so the row keeps its width for the
/// name: a small "you owe" over the amount in bold (DESIGN.md §11 Home).
/// Settled is one muted line.
class BalanceStack extends StatelessWidget {
  const BalanceStack({super.key, required this.net});

  final int net;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = context.moneyColors;
    if (net == 0) {
      return Text(
        l10n.rowSettled,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final color = net > 0 ? money.owed : money.owe;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          net > 0 ? l10n.stackYouAreOwed : l10n.stackYouOwe,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
        Text(
          formatRupees(net.abs()),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
