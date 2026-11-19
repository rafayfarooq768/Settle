import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'app_sheet.dart';

/// A bottom sheet with one text field and a Save-style button
/// (DESIGN.md §8: sheets for small inputs). Returns the trimmed text, or null.
Future<String?> showTextInputSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
  String? helper,
  String? emptyError,
}) {
  return showAppSheet<String>(
    context: context,
    scrollControlled: true,
    builder: (context) => _TextInputSheet(
      title: title,
      label: label,
      action: action,
      initial: initial,
      helper: helper,
      emptyError: emptyError,
    ),
  );
}

class _TextInputSheet extends StatefulWidget {
  const _TextInputSheet({
    required this.title,
    required this.label,
    required this.action,
    required this.initial,
    this.helper,
    this.emptyError,
  });

  final String title;
  final String label;
  final String action;
  final String initial;
  final String? helper;
  final String? emptyError;

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = widget.emptyError);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.screenHorizontal,
        end: AppSpacing.screenHorizontal,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: widget.helper,
              errorText: _error,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: _submit, child: Text(widget.action)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
        ],
      ),
    );
  }
}
