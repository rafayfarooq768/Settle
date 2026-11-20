import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// One line of text at the top of a tab (empty, settled, error). Near the
/// top, not floating mid-screen (DESIGN.md §9, §12 item 15).
class TabMessage extends StatelessWidget {
  const TabMessage(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
    children: [
      const SizedBox(height: AppSpacing.xl),
      Text(text, textAlign: TextAlign.center, style: style),
    ],
  );
}
