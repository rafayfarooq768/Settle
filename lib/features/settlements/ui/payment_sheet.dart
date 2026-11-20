import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/domain/expense_summary.dart';
import '../../profile/domain/payment_method.dart';

/// "Pay Ali" / "Record payment from Ali": the amount starts at what's owed
/// and can be changed to any amount (owner, 2026-11-20). Paying also shows
/// how: the [methods] section (step 10, owner: in this sheet, not a separate
/// screen). Returns paisa, or null if dismissed.
Future<int?> showPaymentSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  required int initial,
  PayMethods? methods,
}) => showAppSheet<int>(
  context: context,
  scrollControlled: true,
  builder: (_) => _PaymentSheet(
    title: title,
    hint: hint,
    action: action,
    initial: initial,
    methods: methods,
  ),
);

/// The person being paid's methods, as they added them, with the label above
/// them ("Ali's payment methods") and what to say when there are none.
typedef PayMethods = ({
  List<PaymentMethod> list,
  String label,
  String emptyText,
});

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.title,
    required this.hint,
    required this.action,
    required this.initial,
    this.methods,
  });

  final String title;
  final PayMethods? methods;

  /// The money line it's settling, e.g. "You owe Ali Rs 300".
  final String hint;
  final String action;
  final int initial;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final _amount = TextEditingController(
    text: RupeeInputFormatter.textFor(widget.initial),
  );
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final paisa = parseRupees(_amount.text);
    final error = paisa == null || paisa == 0
        ? l10n.errorAmountRequired
        : paisa > maxExpenseAmount
        ? l10n.errorAmountTooLarge
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(paisa);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.screenHorizontal,
        end: AppSpacing.screenHorizontal,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(widget.title, inset: false),
              Text(
                widget.hint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AmountField(
                controller: _amount,
                label: l10n.amountLabel,
                prefix: l10n.currencyPrefix,
                error: _error,
                // With the methods below, the keyboard would cover them; the
                // amount is already filled in.
                autofocus: widget.methods == null,
              ),
              if (widget.methods case final m?) ..._methodsSection(context, m),
              const SizedBox(height: AppSpacing.xl),
              LoadingButton(label: widget.action, onPressed: _submit),
              const SizedBox(height: AppSpacing.sm),
              LoadingButton(
                label: l10n.cancelButton,
                style: LoadingButtonStyle.text,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _methodsSection(BuildContext context, PayMethods m) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (m.list.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.xl),
        Text(
          m.emptyText,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ];
    }
    return [
      const SizedBox(height: AppSpacing.xl),
      Text(m.label, style: theme.textTheme.titleSmall?.copyWith(color: muted)),
      const SizedBox(height: AppSpacing.xs),
      for (final (i, method) in m.list.indexed) ...[
        if (i > 0) const Divider(height: 1),
        PayMethodRow(method: method),
      ],
    ];
  }
}

/// One way to pay: the name, the account title, then the
/// number with a copy button. No panel: the sheet is already one.
class PayMethodRow extends StatefulWidget {
  const PayMethodRow({super.key, required this.method});

  final PaymentMethod method;

  @override
  State<PayMethodRow> createState() => _PayMethodRowState();
}

class _PayMethodRowState extends State<PayMethodRow> {
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  /// A SnackBar would sit behind the sheet, so the button itself says it
  /// worked: the copy icon turns into a tick for a moment.
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.method.accountNumber));
    if (!mounted) return;
    _copiedTimer?.cancel();
    setState(() {
      _copiedTimer = Timer(AppMotion.snackBar, () {
        if (mounted) setState(() => _copiedTimer = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final m = widget.method;
    final copied = _copiedTimer != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (m.accountTitle.isNotEmpty)
                  Text(
                    m.accountTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                // Numbers and IBANs read left to right in Urdu too.
                SelectableText(
                  m.accountNumber,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: copied ? l10n.copiedTooltip : l10n.copyNumberTooltip,
            onPressed: _copy,
            icon: Icon(
              copied ? Icons.check : Icons.content_copy_outlined,
              color: copied ? context.extraColors.link : muted,
            ),
          ),
        ],
      ),
    );
  }
}
