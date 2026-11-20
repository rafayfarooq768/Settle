import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';

String _name(AppLocalizations l10n, Member m, String meId) =>
    m.id == meId ? l10n.memberYou(m.displayName) : m.displayName;

/// What [pickPayer] returns for "More than one person".
const morePayers = '';

/// "Who paid?" sheet. One tap picks and closes (DESIGN.md §8). The last
/// row, "More than one person", returns [morePayers]. [selected] is null
/// when several people paid.
Future<String?> pickPayer(
  BuildContext context, {
  required List<Member> members,
  required String meId,
  required String? selected,
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
        if (members.length > 1)
          ListTile(
            minTileHeight: AppSpacing.rowHeight,
            leading: const Icon(Icons.group_outlined),
            title: Text(l10n.payersMore),
            trailing: selected == null
                ? const Icon(Icons.check)
                : const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(sheet).pop(morePayers),
          ),
      ],
    ),
  );
}

/// What [pickTipGiver] returns for "Everyone, equally".
const tipEveryone = '';

/// "Who gives the tip?" sheet: everyone on the bill equally, or one
/// person. [selected] is null for everyone.
Future<String?> pickTipGiver(
  BuildContext context, {
  required List<Member> members,
  required String meId,
  required String? selected,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppSheet<String>(
    context: context,
    scrollControlled: true,
    builder: (sheet) => _SheetList(
      title: l10n.tipGiverTitle,
      children: [
        ListTile(
          minTileHeight: AppSpacing.rowHeight,
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.tipEveryone),
          trailing: selected == null ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(sheet).pop(tipEveryone),
        ),
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

/// Sheet body: title and a scrollable list.
class _SheetList extends StatelessWidget {
  const _SheetList({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(title),
            Flexible(child: ListView(shrinkWrap: true, children: children)),
          ],
        ),
      ),
    );
  }
}
