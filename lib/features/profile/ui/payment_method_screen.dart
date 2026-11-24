import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/payment_method.dart';
import '../domain/payment_methods.dart';
import 'profile_providers.dart';

/// Saves [methods] on your profile and your member doc in every group, so
/// group-mates see them at settle-up (PLAN.md §5).
/// Saves [methods] on your profile and every member doc. Returns a save
/// that keeps working after the screen closes (Undo runs from the
/// SnackBar, when this screen's `ref` is already gone).
Future<void> Function(List<PaymentMethod> methods) paymentMethodSaver(
  WidgetRef ref,
) {
  final uid = ref.read(myIdentityProvider)?.uid;
  final repo = ref.read(groupRepositoryProvider);
  return (methods) async {
    if (uid == null) return;
    await repo.saveMyProfile(uid: uid, paymentMethods: methods);
  };
}

/// Add or edit one payment method (PLAN.md §5): name with suggestions,
/// account title, number. Free text, no format checks.
class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key, this.methodId});

  /// Set when editing.
  final String? methodId;

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _number = TextEditingController();
  String? _nameError;
  String? _numberError;
  PaymentMethod? _original;

  @override
  void initState() {
    super.initState();
    final me = ref.read(myIdentityProvider);
    final list = me?.paymentMethods ?? const <PaymentMethod>[];
    final original = list.where((m) => m.id == widget.methodId).firstOrNull;
    _original = original;
    if (original != null) {
      _name.text = original.name;
      _title.text = original.accountTitle;
      _number.text = original.accountNumber;
    } else {
      // Most accounts are in your own name.
      _title.text = me?.name ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _number.dispose();
    super.dispose();
  }

  List<PaymentMethod> get _current =>
      ref.read(myIdentityProvider)?.paymentMethods ?? const [];

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    final number = _number.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.errorPaymentNameRequired : null;
      _numberError = number.isEmpty ? l10n.errorAccountNumberRequired : null;
    });
    if (_nameError != null || _numberError != null) return;

    final method = PaymentMethod(
      id: _original?.id ?? newPaymentMethodId(),
      name: name,
      accountTitle: _title.text.trim(),
      accountNumber: number,
    );
    _write(saveMethod(_current, method), l10n.paymentMethodSaved);
  }

  /// Delete with Undo instead of a confirmation (DESIGN.md §8).
  void _delete() {
    final l10n = AppLocalizations.of(context)!;
    final original = _original!;
    final before = _current;
    final save = paymentMethodSaver(ref);
    _write(
      removeMethod(before, original.id),
      l10n.paymentMethodDeleted,
      undo: () => save(before),
    );
  }

  void _write(List<PaymentMethod> methods, String done, {VoidCallback? undo}) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    paymentMethodSaver(ref)(methods)
        .catchError((Object e) => messenger.showMessage(errorText(l10n, e)));
    messenger.showMessage(
      done,
      undoLabel: undo == null ? null : l10n.undoButton,
      onUndo: undo,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = _original != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? l10n.editPaymentMethodTitle : l10n.addPaymentMethodTitle,
        ),
      ),
      body: ScreenLayout(
        body: [
          const SizedBox(height: AppSpacing.lg),
          _NameField(controller: _name, error: _nameError, autofocus: !editing),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _title,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.accountTitleLabel,
              helperText: l10n.accountTitleHelper,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _number,
            maxLength: 40,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.accountNumberLabel,
              errorText: _numberError,
              counterText: '',
            ),
          ),
        ],
        actions: [
          LoadingButton(label: l10n.saveButton, onPressed: _save),
          if (editing) ...[
            const SizedBox(height: AppSpacing.sm),
            LoadingButton(
              label: l10n.deletePaymentMethodButton,
              style: LoadingButtonStyle.text,
              foregroundColor: context.moneyColors.owe,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

/// The name, free text, with chips for the common banks and wallets.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    this.error,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? error;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = l10n.paymentMethodNameSuggestions.split(',');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodNameLabel,
            helperText: l10n.paymentMethodNameHelper,
            errorText: error,
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in suggestions)
                ChoiceChip(
                  label: Text(s),
                  selected: controller.text.trim() == s,
                  onSelected: (_) => controller.text = s,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
