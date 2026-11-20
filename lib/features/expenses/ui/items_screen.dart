import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/inline_number_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/split_spec.dart';
import 'expense_pickers.dart';
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
/// service (% of the items or Rs, tap the unit), shared by what each
/// person had, and a tip in rupees: equally, or given by one person. Not
/// shared by what each
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
  late bool _taxPercent = (widget.args.spec?.taxRs ?? 0) == 0;
  late bool _servicePercent = (widget.args.spec?.serviceRs ?? 0) == 0;
  late final _tax = _controller(
    _taxPercent
        ? _percentText(widget.args.spec?.taxBp)
        : _rupeeText(widget.args.spec?.taxRs),
  );
  late final _service = _controller(
    _servicePercent
        ? _percentText(widget.args.spec?.serviceBp)
        : _rupeeText(widget.args.spec?.serviceRs),
  );
  late final _tip = _controller(_rupeeText(widget.args.spec?.tip));
  late String? _tipBy = widget.args.spec?.tipBy;

  static String _percentText(int? bp) =>
      bp == null || bp == 0 ? '' : formatPercent(bp).replaceAll('%', '');

  static String _rupeeText(int? paisa) =>
      paisa == null || paisa == 0 ? '' : RupeeInputFormatter.textFor(paisa);

  TextEditingController _controller(String text) =>
      TextEditingController(text: text)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tax.dispose();
    _service.dispose();
    _tip.dispose();
    super.dispose();
  }

  ItemizedSpec get _spec => ItemizedSpec(
    items: _items,
    taxBp: _taxPercent ? parsePercent(_tax.text) ?? 0 : 0,
    taxRs: _taxPercent ? 0 : parseRupees(_tax.text) ?? 0,
    serviceBp: _servicePercent ? parsePercent(_service.text) ?? 0 : 0,
    serviceRs: _servicePercent ? 0 : parseRupees(_service.text) ?? 0,
    tip: parseRupees(_tip.text) ?? 0,
    tipBy: _tipBy,
  );

  /// Flips Tax or Service between % and Rs, keeping what it comes to
  /// (16% of Rs 3,000 becomes Rs 480 and back) so the total doesn't jump.
  void _flipUnit(TextEditingController field, bool percent, int rupees) {
    final items = _spec.itemsTotal;
    final String text;
    if (percent) {
      text = _rupeeText(rupees);
    } else {
      // Nearest basis point; can be off by a paisa when it comes back.
      final bp = items == 0
          ? 0
          : (rupees * fullPercentBp + items ~/ 2) ~/ items;
      text = bp > fullPercentBp ? '' : _percentText(bp);
    }
    setState(() {
      if (identical(field, _tax)) {
        _taxPercent = !percent;
      } else {
        _servicePercent = !percent;
      }
      field.text = text;
    });
  }

  Future<void> _pickTipGiver(List<Member> members) async {
    final picked = await pickTipGiver(
      context,
      members: members,
      meId: widget.args.meId,
      selected: _tipBy,
    );
    if (picked == null || !mounted) return;
    setState(() => _tipBy = picked == tipEveryone ? null : picked);
  }

  /// Add (no [index]) or edit an item.
  Future<void> _edit(List<Member> members, {int? index}) async {
    final list = _items;
    final result = await showItemSheet(
      context,
      members: members,
      meId: widget.args.meId,
      line: index == null ? null : list[index],
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
    final spec = _spec;
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
          SectionLabel(l10n.extrasSection),
          Panel(
            dividerIndent: AppSpacing.lg,
            children: [
              _ExtraRow(
                label: l10n.taxLabel,
                controller: _tax,
                percent: _taxPercent,
                amount: spec.tax,
                onFlip: () => _flipUnit(_tax, _taxPercent, spec.tax),
              ),
              _ExtraRow(
                label: l10n.serviceLabel,
                controller: _service,
                percent: _servicePercent,
                amount: spec.service,
                onFlip: () =>
                    _flipUnit(_service, _servicePercent, spec.service),
              ),
              _ExtraRow(label: l10n.tipLabel, controller: _tip),
              if (spec.tip > 0)
                _TipGiverRow(
                  value: switch (_tipBy) {
                    final id? when byId[id] != null => memberName(
                      l10n,
                      byId[id]!,
                      widget.args.meId,
                    ),
                    _ => l10n.tipEveryone,
                  },
                  onTap: () => _pickTipGiver(members),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal + AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.screenHorizontal + AppSpacing.lg,
              0,
            ),
            child: Text(
              l10n.extrasByOrderNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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

/// Tax / Service (% or Rs, tap the unit to switch) or Tip (Rs). A % shows
/// the rupees it comes to under the label.
class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.label,
    required this.controller,
    this.percent = false,
    this.amount = 0,
    this.onFlip,
  });

  final String label;
  final TextEditingController controller;
  final bool percent;

  /// What it comes to, shown under the label for a %.
  final int amount;

  /// Null for Tip (always rupees).
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      // The unit slot has its own inner space; a smaller row end keeps
      // the panel's right edge even.
      contentPadding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
      ),
      title: Text(label),
      subtitle: percent && amount > 0 ? Text(formatRupees(amount)) : null,
      trailing: InlineNumberField(
        controller: controller,
        percent: percent,
        unit: percent ? l10n.percentSuffix : l10n.currencyPrefix,
        onUnitTap: onFlip,
        unitTapHint: onFlip == null ? null : l10n.unitSwitchHint,
        unitAtEnd: true,
      ),
    );
  }
}

/// "Who gives the tip" with its value and a chevron; opens a sheet.
class _TipGiverRow extends StatelessWidget {
  const _TipGiverRow({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      title: Text(l10n.tipGiverLabel),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.extraColors.link,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
