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
/// reads as tappable; it stays at the end so the row doesn't jump when it
/// changes.
class InlineNumberField extends StatelessWidget {
  const InlineNumberField({
    super.key,
    required this.controller,
    required this.unit,
    this.percent = false,
    this.onUnitTap,
    this.unitTapHint,
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
        children: onUnitTap != null
            ? [
                field,
                _UnitButton(unit: unit, hint: unitTapHint, onTap: onUnitTap!),
              ]
            : percent
            ? [field, const SizedBox(width: AppSpacing.xs), unitText]
            : [unitText, const SizedBox(width: AppSpacing.sm), field],
      ),
    );
  }
}

/// "% ▾": the unit as a quiet teal button.
class _UnitButton extends StatelessWidget {
  const _UnitButton({required this.unit, required this.onTap, this.hint});

  final String unit;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final link = context.extraColors.link;
    return Semantics(
      button: true,
      hint: hint,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.tapTarget,
              minHeight: AppSizes.tapTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.sm,
                end: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: link, fontWeight: FontWeight.w600),
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
