import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';

String _name(AppLocalizations l10n, Member m, String meId) =>
    m.id == meId ? l10n.memberYou(m.displayName) : m.displayName;

/// "Who paid?" sheet. One tap picks and closes (DESIGN.md §8).
Future<String?> pickPayer(
  BuildContext context, {
  required List<Member> members,
  required String meId,
  required String selected,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppSheet<String>(
    context: context,
    scrollControlled: true,
    builder: (sheet) => _SheetList(
      title: l10n.whoPaidTitle,
      children: [
        for (final m in members)
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            leading: MemberAvatar(
              name: m.displayName,
              placeholder: m.isPlaceholder,
            ),
            title: Text(_name(l10n, m, meId)),
            trailing: m.id == selected ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(sheet).pop(m.id),
          ),
      ],
    ),
  );
}

/// "Who was there?" sheet: tick people, then Done. Done stays disabled
/// while nobody is ticked, since an equal split needs someone.
Future<Set<String>?> pickParticipants(
  BuildContext context, {
  required List<Member> members,
  required String meId,
  required Set<String> selected,
}) {
  final l10n = AppLocalizations.of(context)!;
  final ticked = {...selected};
  return showAppSheet<Set<String>>(
    context: context,
    scrollControlled: true,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) => _SheetList(
        title: l10n.whoWasThereTitle,
        action: LoadingButton(
          label: l10n.doneButton,
          onPressed: ticked.isEmpty
              ? null
              : () => Navigator.of(sheet).pop(ticked),
        ),
        children: [
          for (final m in members)
            CheckboxListTile(
              value: ticked.contains(m.id),
              onChanged: (on) => setState(
                () => on == true ? ticked.add(m.id) : ticked.remove(m.id),
              ),
              secondary: MemberAvatar(
                name: m.displayName,
                placeholder: m.isPlaceholder,
              ),
              title: Text(_name(l10n, m, meId)),
            ),
        ],
      ),
    ),
  );
}

/// Sheet body: title, a scrollable list, and an optional bottom action.
class _SheetList extends StatelessWidget {
  const _SheetList({required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal + AppSpacing.lg,
                0,
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
              ),
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
            Flexible(child: ListView(shrinkWrap: true, children: children)),
            if (action != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: action,
              ),
          ],
        ),
      ),
    );
  }
}
