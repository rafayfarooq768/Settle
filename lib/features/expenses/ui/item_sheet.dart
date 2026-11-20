import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../domain/split_spec.dart';
import 'split_screen.dart';

/// What the item sheet returns: the saved line, or null [line] for Delete.
class ItemSheetResult {
  const ItemSheetResult(this.line);
  final BillLine? line;
}

/// Add or edit one bill item: name, price, who had it (DESIGN.md §8: a
/// sheet for a small form). New items start with everyone ticked, so a
/// shared item is one tap less.
Future<ItemSheetResult?> showItemSheet(
  BuildContext context, {
  required List<Member> members,
  required String meId,
  BillLine? line,
}) => showAppSheet<ItemSheetResult>(
  context: context,
  scrollControlled: true,
  builder: (_) => _ItemSheet(members: members, meId: meId, line: line),
);

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.members, required this.meId, this.line});

  final List<Member> members;
  final String meId;
  final BillLine? line;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final _name = TextEditingController(text: widget.line?.name ?? '');
  late final _price = TextEditingController(
    text: widget.line == null
        ? ''
        : RupeeInputFormatter.textFor(widget.line!.amount),
  );
  late final Set<String> _who = {
    ...?widget.line?.memberIds,
    if (widget.line == null) ...widget.members.map((m) => m.id),
  };
  String? _priceError;
  String? _whoError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final price = parseRupees(_price.text);
    setState(() {
      _priceError = price == null || price == 0
          ? l10n.errorAmountRequired
          : null;
      _whoError = _who.isEmpty ? l10n.errorPickWhoHad : null;
    });
    if (_priceError != null || _whoError != null) return;
    Navigator.of(context).pop(
      ItemSheetResult(
        BillLine(
          name: _name.text.trim(),
          amount: price!,
          memberIds: [
            for (final m in widget.members)
              if (_who.contains(m.id)) m.id,
          ],
        ),
      ),
    );
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
              SheetTitle(
                widget.line == null ? l10n.itemAddTitle : l10n.itemEditTitle,
                inset: false,
              ),
              TextField(
                controller: _name,
                autofocus: widget.line == null,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.itemNameLabel,
                  hintText: l10n.itemNameHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[RupeeInputFormatter()],
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  labelText: l10n.itemPriceLabel,
                  prefixText: '${l10n.currencyPrefix} ',
                  errorText: _priceError,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.itemWhoHad,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _whoError == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final m in widget.members)
                    FilterChip(
                      label: Text(memberName(l10n, m, widget.meId)),
                      selected: _who.contains(m.id),
                      onSelected: (on) => setState(() {
                        on ? _who.add(m.id) : _who.remove(m.id);
                        _whoError = null;
                      }),
                    ),
                ],
              ),
              if (_whoError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _whoError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              LoadingButton(label: l10n.itemSaveButton, onPressed: _save),
              if (widget.line != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LoadingButton(
                  label: l10n.itemDeleteButton,
                  style: LoadingButtonStyle.text,
                  foregroundColor: context.moneyColors.owe,
                  onPressed: () =>
                      Navigator.of(context).pop(const ItemSheetResult(null)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
