import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// The last row of a panel that adds to it: the label in teal with a + at
/// the end ("New group or join", "Add item", "Add payment method").
class AddRow extends StatelessWidget {
  const AddRow({
    super.key,
    required this.label,
    required this.onTap,
    this.contentPadding,
  });

  final String label;
  final VoidCallback onTap;

  /// [chevronRowPadding] in panels whose other rows end with a chevron,
  /// so the + lines up with them.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final link = context.extraColors.link;
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      contentPadding: contentPadding,
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: link),
      ),
      trailing: Icon(Icons.add, color: link),
      onTap: onTap,
    );
  }
}
