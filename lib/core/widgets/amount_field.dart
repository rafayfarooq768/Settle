import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// The amount on Add expense (DESIGN.md §6, owner 2026-11-20): a big
/// centred number with "Rs", no box, a teal underline while focused, and
/// thousand separators as you type. The screen's one large number.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefix,
    this.error,
    this.autofocus = true,
  });

  final TextEditingController controller;

  /// Read out by screen readers ("Amount"); not shown.
  final String label;

  /// "Rs" from the ARB file.
  final String prefix;
  final String? error;
  final bool autofocus;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _focus = FocusNode();

  /// Enough room for the "0" hint and the cursor when empty.
  static const double _minNumberWidth = 48;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final big = theme.textTheme.headlineLarge;
    final muted = scheme.onSurfaceVariant;
    final error = widget.error;
    final lineColor = error != null
        ? scheme.error
        : _focus.hasFocus
        ? scheme.primary
        : scheme.outline;

    return Column(
      children: [
        // "Rs" and the number move together as one centred unit, with the
        // underline only under them (it grows as you type).
        GestureDetector(
          onTap: _focus.requestFocus,
          child: Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: lineColor,
                  width: _focus.hasFocus || error != null
                      ? AppSizes.focusLine
                      : 1,
                ),
              ),
            ),
            child: Directionality(
              // Amounts read left to right in Urdu too.
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // Small "Rs" so the number carries the weight
                  // (DESIGN (3).md §3, polish 2026-11-20).
                  Text(
                    widget.prefix,
                    style: big?.copyWith(
                      fontSize: (big.fontSize ?? 32) * 0.6,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: _minNumberWidth,
                    ),
                    child: IntrinsicWidth(
                      child: Semantics(
                        label: widget.label,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          autofocus: widget.autofocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          inputFormatters: [RupeeInputFormatter()],
                          style: big,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: big?.copyWith(color: muted),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// Keeps digits and one dot with at most 2 decimals, and groups the
/// rupees with commas: "1200.5" → "1,200.5". `parseRupees` reads it back.
class RupeeInputFormatter extends TextInputFormatter {
  /// Up to Rs 999,999,999,999: more than the Rs 1 billion limit, so the
  /// "too large" message can still show.
  static const _maxWholeDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final dot = raw.indexOf('.');
    var whole = dot < 0 ? raw : raw.substring(0, dot);
    final fraction = dot < 0
        ? null
        : raw.substring(dot + 1).replaceAll('.', '');
    if (fraction != null && fraction.length > 2) return oldValue;
    whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (whole.length > _maxWholeDigits) return oldValue;
    final text =
        '${groupThousands(whole)}${fraction == null ? '' : '.$fraction'}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// What the field shows for [paisa]: "1,200", or "1,200.50" when
  /// paisa aren't zero. `parseRupees` reads it back to the same value.
  static String textFor(int paisa) {
    final whole = groupThousands('${paisa ~/ 100}');
    final cents = paisa % 100;
    return cents == 0 ? whole : '$whole.${'$cents'.padLeft(2, '0')}';
  }

  static String groupThousands(String digits) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
