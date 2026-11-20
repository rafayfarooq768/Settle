import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
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

/// "Who gives the tip?" sheet. "Everyone, equally" picks and closes
/// (returns an empty list); otherwise tick one or more people and Done.
/// [selected] empty = everyone. Null = closed without choosing.
Future<List<String>?> pickTipGivers(
  BuildContext context, {
  required List<Member> members,
  required String meId,
  required List<String> selected,
}) => showAppSheet<List<String>>(
  context: context,
  scrollControlled: true,
  builder: (_) =>
      _TipGiversSheet(members: members, meId: meId, selected: selected),
);

class _TipGiversSheet extends StatefulWidget {
  const _TipGiversSheet({
    required this.members,
    required this.meId,
    required this.selected,
  });

  final List<Member> members;
  final String meId;
  final List<String> selected;

  @override
  State<_TipGiversSheet> createState() => _TipGiversSheetState();
}

class _TipGiversSheetState extends State<_TipGiversSheet> {
  late final Set<String> _ticked = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final everyone = widget.selected.isEmpty;
    return _SheetList(
      title: l10n.tipGiverTitle,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          AppSpacing.lg,
        ),
        child: LoadingButton(
          label: l10n.doneButton,
          onPressed: _ticked.isEmpty
              ? null
              : () => Navigator.of(context).pop([
                  for (final m in widget.members)
                    if (_ticked.contains(m.id)) m.id,
                ]),
        ),
      ),
      children: [
        ListTile(
          minTileHeight: AppSpacing.rowHeight,
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.tipEveryone),
          trailing: everyone && _ticked.isEmpty
              ? const Icon(Icons.check)
              : null,
          onTap: () => Navigator.of(context).pop(const <String>[]),
        ),
        for (final m in widget.members)
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            secondary: MemberAvatar(
              name: m.displayName,
              placeholder: m.isPlaceholder,
            ),
            title: Text(_name(l10n, m, widget.meId)),
            value: _ticked.contains(m.id),
            onChanged: (on) => setState(
              () => on == true ? _ticked.add(m.id) : _ticked.remove(m.id),
            ),
          ),
      ],
    );
  }
}

/// Sheet body: title and a scrollable list.
class _SheetList extends StatelessWidget {
  const _SheetList({required this.title, required this.children, this.footer});

  final String title;
  final List<Widget> children;

  /// Pinned under the list (a Done button).
  final Widget? footer;

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
            ?footer,
          ],
        ),
      ),
    );
  }
}
