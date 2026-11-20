import 'package:material_ui/material_ui.dart';

import 'empty_state.dart';

/// One line at the top of a tab (empty, settled, error): an [EmptyState]
/// with no actions, so it lines up with every other empty state.
class TabMessage extends StatelessWidget {
  const TabMessage(this.text, {super.key, this.color});

  final String text;

  /// e.g. the settled colour for "Everyone is settled up".
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      EmptyState(title: text, titleColor: color);
}
