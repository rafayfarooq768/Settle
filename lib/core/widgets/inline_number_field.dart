import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money/money.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import 'amount_field.dart';
import 'press_scale.dart';

/// A number at the end of a list row: no box, just the figure on a thin
/// underline that turns teal while you type, like the big [AmountField]
/// (owner, 2026-11-20: "no big square placeholders"). It grows with the
/// number. The unit sits beside it: "Rs 300" or "16 %".
///
/// With [onUnitTap] the unit becomes a small teal button with a ▾ so it
/// reads as tappable. With [unitAtEnd] (or [onUnitTap]) the unit sits in
/// a fixed slot after the number, so the numbers of rows in one panel
/// line up whether their unit is tappable or not.
class InlineNumberField extends StatelessWidget {
  const InlineNumberField({
    super.key,
    required this.controller,
    required this.unit,
    this.percent = false,
    this.onUnitTap,
    this.unitTapHint,
    this.unitAtEnd = false,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;

  /// "Rs" or "%".
  final String unit;

  /// Percent input (0–100, 2 decimals) instead of rupees.
  final bool percent;

  /// Makes the unit a toggle (Tax / Service: % or Rs).
  final VoidCallback? onUnitTap;

  /// What the unit button does, for screen readers.
  final String? unitTapHint;

  /// "300 Rs" in the end slot instead of "Rs 300".
  final bool unitAtEnd;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final number = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final line = UnderlineInputBorder(
      borderSide: BorderSide(color: theme.colorScheme.outline),
    );
    final field = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSizes.inlineFieldMinWidth,
        maxWidth: AppSizes.inlineFieldMaxWidth,
      ),
      child: IntrinsicWidth(
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            percent ? PercentInputFormatter() : RupeeInputFormatter(),
          ],
          textAlign: TextAlign.end,
          textInputAction: textInputAction,
          style: number,
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            hintText: '0',
            hintStyle: number?.copyWith(color: muted),
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            border: line,
            enabledBorder: line,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: AppSizes.focusLine,
              ),
            ),
          ),
        ),
      ),
    );
    final unitText = Text(
      unit,
      style: theme.textTheme.titleMedium?.copyWith(color: muted),
    );

    // Amounts read left to right in Urdu too.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: onUnitTap != null || unitAtEnd
            ? [
                field,
                _UnitSlot(unit: unit, hint: unitTapHint, onTap: onUnitTap),
              ]
            : percent
            ? [field, const SizedBox(width: AppSpacing.xs), unitText]
            : [unitText, const SizedBox(width: AppSpacing.sm), field],
      ),
    );
  }
}

/// The unit after the number, in a fixed-width slot: "% ▾" as a quiet
/// teal button when [onTap] is set, otherwise plain muted "Rs".
class _UnitSlot extends StatelessWidget {
  const _UnitSlot({required this.unit, this.onTap, this.hint});

  final String unit;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (onTap == null) {
      return SizedBox(
        width: AppSizes.unitSlotWidth,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: Text(
            unit,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final link = context.extraColors.link;
    return Semantics(
      button: true,
      hint: hint,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: SizedBox(
            width: AppSizes.unitSlotWidth,
            height: AppSizes.tapTarget,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    unit,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: link,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: link),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Digits and one dot, at most 2 decimals, at most 100.
class PercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d{1,3}(\.\d{0,2})?$').hasMatch(text)) return oldValue;
    return parsePercent(text) == null ? oldValue : newValue;
  }
}
