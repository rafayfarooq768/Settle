import 'package:flutter/material.dart';

/// Inline, plain-words message under a form (DESIGN.md §6 Inputs: no popups).
/// Errors use the theme's error colour, not the owe/owed money colours,
/// which are reserved for amounts (DESIGN.md §2).
class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {super.key, this.isError = true});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isError ? theme.colorScheme.error : null,
      ),
    );
  }
}
