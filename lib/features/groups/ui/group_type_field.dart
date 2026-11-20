import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Free-text group type with tappable suggestions (PLAN.md §6).
class GroupTypeField extends StatelessWidget {
  const GroupTypeField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = [
      l10n.groupTypeFriends,
      l10n.groupTypeTrip,
      l10n.groupTypeHome,
      l10n.groupTypeOffice,
      l10n.groupTypeFamily,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.groupTypeLabel,
            helperText: l10n.groupTypeHelper,
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
