import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/split_spec.dart';
import 'item_sheet.dart';
import 'split_screen.dart';

/// What the split screen hands the items screen.
class ItemsArgs {
  const ItemsArgs({
    required this.amount,
    required this.meId,
    required this.payerIds,
    this.spec,
  });

  /// Paisa typed on Add expense, or null.
  final int? amount;
  final String meId;
  final List<String> payerIds;

  /// The bill so far, when editing.
  final ItemizedSpec? spec;
}

/// Itemized split (PLAN.md §3 item 6, §4): items → people, then tax and
/// service as a % of the items and a tip in rupees, spread by what each
/// person had (or equally). "Who owes what" shows the result live. Done
/// pops the [ItemizedSpec]; its total becomes the expense amount.
class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key, required this.groupId, required this.args});

  final String groupId;
  final ItemsArgs args;

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  late final List<BillLine> _items = [...?widget.args.spec?.items];
  late final List<BillLine> _shared = [...?widget.args.spec?.shared];
  late final _tax = _controller(_percentText(widget.args.spec?.taxBp));
  late final _service = _controller(_percentText(widget.args.spec?.serviceBp));
  late final _tip = _controller(switch (widget.args.spec?.tip) {
    final t? when t > 0 => RupeeInputFormatter.textFor(t),
    _ => '',
  });
  late bool _equally = widget.args.spec?.spread == ExtrasSpread.equal;

  static String _percentText(int? bp) =>
      bp == null || bp == 0 ? '' : formatPercent(bp).replaceAll('%', '');

  TextEditingController _controller(String text) =>
      TextEditingController(text: text)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tax.dispose();
    _service.dispose();
    _tip.dispose();
    super.dispose();
  }

  ItemizedSpec _spec(List<String> order) => ItemizedSpec(
    items: _items,
    shared: _shared,
    sharedWith: sharedWithFor(_items, order),
    taxBp: parsePercent(_tax.text) ?? 0,
    serviceBp: parsePercent(_service.text) ?? 0,
    tip: parseRupees(_tip.text) ?? 0,
    spread: _equally ? ExtrasSpread.equal : ExtrasSpread.proportional,
  );

  /// Add (no [index]) or edit an item, in [_shared] when [shared].
  Future<void> _edit(
    List<Member> members, {
    int? index,
    bool shared = false,
  }) async {
    final list = shared ? _shared : _items;
    final result = await showItemSheet(
      context,
      members: members,
      meId: widget.args.meId,
      line: index == null ? null : list[index],
      shared: shared,
    );
    if (result == null || !mounted) return;
    setState(() {
      final line = result.line;
      if (index == null) {
        if (line != null) list.add(line);
      } else if (line == null) {
        list.removeAt(index);
      } else {
        list[index] = line;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final members =
        (ref.watch(membersProvider(widget.groupId)).valueOrNull ??
                const <Member>[])
            .where((m) => m.active)
            .toList();
    final byId = {for (final m in members) m.id: m};
    final order = [for (final m in members) m.id];
    final spec = _spec(order);
    final ready = spec.problem(null) == null;
    final owes = ready
        ? spec.shares(
            amount: spec.total,
            order: order,
            payers: widget.args.payerIds,
          )
        : const <String, int>{};
    final typed = widget.args.amount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemsTitle)),
      body: ScreenLayout(
        padded: false,
        body: [
          SectionLabel(l10n.itemsSection),
          Panel(
            dividerIndent: AppSpacing.lg,
            children: [
              for (var i = 0; i < _items.length; i++)
                _ItemRow(
                  line: _items[i],
                  people: _peopleText(l10n, _items[i], members, byId),
                  onTap: () => _edit(members, index: i),
                ),
              _AddRow(label: l10n.itemsAdd, onTap: () => _edit(members)),
            ],
          ),
          SectionLabel(l10n.sharedSection),
          Panel(
            dividerIndent: AppSpacing.lg,
            children: [
              for (var i = 0; i < _shared.length; i++)
                _ItemRow(
                  line: _shared[i],
                  people: l10n.sharedSplitBetween(spec.sharedWith.length),
                  onTap: () => _edit(members, index: i, shared: true),
                ),
              _AddRow(
                label: l10n.sharedAdd,
                onTap: () => _edit(members, shared: true),
              ),
            ],
          ),
          SectionLabel(l10n.extrasSection),
          Panel(
            dividerIndent: AppSpacing.lg,
            children: [
              _ExtraRow(
                label: l10n.taxLabel,
                controller: _tax,
                percent: true,
                amount: spec.tax,
              ),
              _ExtraRow(
                label: l10n.serviceLabel,
                controller: _service,
                percent: true,
                amount: spec.service,
              ),
              _ExtraRow(label: l10n.tipLabel, controller: _tip),
              SwitchListTile(
                title: Text(l10n.extrasEqually),
                subtitle: Text(l10n.extrasEquallyHelp),
                value: _equally,
                onChanged: (on) => setState(() => _equally = on),
              ),
            ],
          ),
          if (owes.isNotEmpty) ...[
            SectionLabel(l10n.whoOwesSection),
            Panel(
              dividerIndent: avatarRowDividerIndent,
              children: [
                for (final m in members)
                  if (owes[m.id] case final paisa?)
                    ListTile(
                      minTileHeight: AppSpacing.rowHeight,
                      leading: MemberAvatar(
                        name: m.displayName,
                        placeholder: m.isPlaceholder,
                      ),
                      title: Text(memberName(l10n, m, widget.args.meId)),
                      trailing: Text(
                        formatRupees(paisa),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
        actions: [
          Text(
            l10n.billTotal(formatRupees(spec.total)),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (typed != null && typed > 0 && typed != spec.total && ready) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.billTotalChanges(formatRupees(typed)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          LoadingButton(
            label: l10n.doneButton,
            onPressed: ready ? () => context.pop(spec) : null,
          ),
        ],
      ),
    );
  }

  /// "Everyone", or the names of who had it.
  String _peopleText(
    AppLocalizations l10n,
    BillLine line,
    List<Member> members,
    Map<String, Member> byId,
  ) {
    if (members.isNotEmpty && line.memberIds.length == members.length) {
      return l10n.itemEveryone;
    }
    return [
      for (final id in line.memberIds)
        if (byId[id] case final m?)
          m.id == widget.args.meId ? l10n.youLabel : m.displayName,
    ].join(', ');
  }
}

/// An item: name and who had it, price at the end. Tap to edit.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.line,
    required this.people,
    required this.onTap,
  });

  final BillLine line;
  final String people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(line.name.isEmpty ? l10n.itemUnnamed : line.name),
      subtitle: Text(people, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatRupees(line.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      onTap: onTap,
    );
  }
}

/// "Add item" in teal with a + at the end, like Home's "New group" row.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final link = context.extraColors.link;
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: link),
      ),
      trailing: Icon(Icons.add, color: link),
      onTap: onTap,
    );
  }
}

/// Tax / Service (a %) or Tip (rupees), with the rupees a % works out to.
class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.label,
    required this.controller,
    this.percent = false,
    this.amount = 0,
  });

  final String label;
  final TextEditingController controller;
  final bool percent;

  /// What the % comes to, shown under the label when not zero.
  final int amount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(label),
      subtitle: percent && amount > 0 ? Text(formatRupees(amount)) : null,
      trailing: UnitNumberField(controller: controller, percent: percent),
    );
  }
}
