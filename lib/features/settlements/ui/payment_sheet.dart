import 'package:material_ui/material_ui.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/domain/expense_summary.dart';

/// "Pay Ali" / "Record payment from Ali": the amount starts at what's owed
/// and can be changed to any amount (owner, 2026-11-20). Returns paisa,
/// or null if dismissed.
Future<int?> showPaymentSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  required int initial,
}) => showAppSheet<int>(
  context: context,
  scrollControlled: true,
  builder: (_) =>
      _PaymentSheet(title: title, hint: hint, action: action, initial: initial),
);

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.title,
    required this.hint,
    required this.action,
    required this.initial,
  });

  final String title;

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
            ),
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
    );
  }
}
