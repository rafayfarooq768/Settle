import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/expense.dart';
import '../domain/split_spec.dart';
import 'items_screen.dart';
import 'split_text.dart';

/// What Add expense hands the split screen.
class SplitArgs {
  const SplitArgs({
    required this.amount,
    required this.payerIds,
    required this.meId,
    required this.spec,
  });

  /// Paisa, or null if the amount isn't entered yet.
  final int? amount;

  /// Who paid, in group order (leftover paisa go to them first).
  final List<String> payerIds;
  final String meId;
  final SplitSpec spec;
}

/// The split screen (DESIGN.md §11 Add expense): Equal / Exact / %
/// as a SegmentedButton, the members below, a live "Rs X left" line, and
/// Done only once it adds up. Pops with the new [SplitSpec].
class SplitScreen extends ConsumerStatefulWidget {
  const SplitScreen({super.key, required this.groupId, required this.args});

  final String groupId;
  final SplitArgs args;

  @override
  ConsumerState<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends ConsumerState<SplitScreen> {
  /// An itemized bill has its own screen; here it starts on Equal.
  late SplitMode _mode = widget.args.spec is ItemizedSpec
      ? SplitMode.equal
      : widget.args.spec.mode;

  /// Who's ticked in Equal; null = everyone (set once members load).
  late Set<String>? _ticked = switch (widget.args.spec) {
    EqualSpec(:final participants) => {...participants},
    _ => null,
  };

  /// One text field per person per mode, so switching modes keeps what
  /// was typed.
  final _fields = <SplitMode, Map<String, TextEditingController>>{};

  @override
  void initState() {
    super.initState();
    final spec = widget.args.spec;
    switch (spec) {
      case ExactSpec(:final amounts):
        amounts.forEach(
          (id, p) =>
              _field(SplitMode.exact, id, RupeeInputFormatter.textFor(p)),
        );
      case PercentSpec(:final basisPoints):
        basisPoints.forEach(
          (id, bp) => _field(
            SplitMode.percent,
            id,
            formatPercent(bp).replaceAll('%', ''),
          ),
        );
      case EqualSpec() || ItemizedSpec():
        break;
    }
  }

  @override
  void dispose() {
    for (final byId in _fields.values) {
      for (final c in byId.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  /// The field for [id] in [mode], made with [initial] the first time.
  TextEditingController _field(
    SplitMode mode,
    String id, [
    String initial = '',
  ]) =>
      (_fields[mode] ??= {})[id] ??= TextEditingController(text: initial)
        ..addListener(() => setState(() {}));

  void _switchTo(SplitMode mode) => setState(() => _mode = mode);

  SplitSpec _spec(List<Member> members) {
    Map<String, int> read(SplitMode mode, int? Function(String) parse) => {
      for (final m in members)
        m.id: parse(_fields[mode]?[m.id]?.text ?? '') ?? 0,
    };
    return switch (_mode) {
      SplitMode.equal => EqualSpec([
        for (final m in members)
          if (_ticked!.contains(m.id)) m.id,
      ]),
      SplitMode.exact => ExactSpec(read(SplitMode.exact, parseRupees)),
      // Percent (itemized has its own screen).
      _ => PercentSpec(read(SplitMode.percent, parsePercent)),
    };
  }

  /// The bill screen; its result is this screen's result too.
  Future<void> _openItems() async {
    final bill = await context.push<ItemizedSpec>(
      '/groups/${widget.groupId}/items',
      extra: ItemsArgs(
        amount: widget.args.amount,
        meId: widget.args.meId,
        payerIds: widget.args.payerIds,
        spec: switch (widget.args.spec) {
          final ItemizedSpec bill => bill,
          _ => null,
        },
      ),
    );
    if (bill != null && mounted) context.pop(bill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final amount = widget.args.amount;
    final members =
        (ref.watch(membersProvider(widget.groupId)).valueOrNull ??
                const <Member>[])
            .where((m) => m.active)
            .toList();
    if (_ticked == null && members.isNotEmpty) {
      _ticked = {for (final m in members) m.id};
    }
    final ticked = _ticked ?? const <String>{};
    final spec = _spec(members);
    final problem = spec.problem(amount);
    // What each person ends up owing, shown under their name.
    final preview = problem == null && amount != null && amount > 0
        ? spec.shares(
            amount: amount,
            order: [for (final m in members) m.id],
            payers: widget.args.payerIds,
          )
        : const <String, int>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          amount == null || amount == 0
              ? l10n.splitTitle
              : l10n.splitTitleAmount(formatRupees(amount)),
        ),
      ),
      body: ScreenLayout(
        padded: false,
        body: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: SegmentedButton<SplitMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SplitMode.equal,
                  label: Text(l10n.splitModeEqual),
                ),
                ButtonSegment(
                  value: SplitMode.exact,
                  label: Text(l10n.splitModeExact),
                ),
                ButtonSegment(
                  value: SplitMode.percent,
                  label: Text(l10n.splitModePercent),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _switchTo(s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.screenHorizontal + AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              switch (_mode) {
                SplitMode.equal => l10n.splitHintEqual,
                SplitMode.exact => l10n.splitHintExact,
                _ => l10n.splitHintPercent,
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Panel(
            dividerIndent: avatarRowDividerIndent,
            children: [
              for (final m in members)
                _mode == SplitMode.equal
                    ? _TickRow(
                        member: m,
                        meId: widget.args.meId,
                        ticked: ticked.contains(m.id),
                        owes: preview[m.id],
                        onChanged: (on) => setState(
                          () => on ? _ticked!.add(m.id) : _ticked!.remove(m.id),
                        ),
                      )
                    : SplitInputRow(
                        member: m,
                        meId: widget.args.meId,
                        mode: _mode,
                        controller: _field(_mode, m.id),
                        owes: _mode == SplitMode.exact ? null : preview[m.id],
                      ),
            ],
          ),
          _ItemsLink(
            label: widget.args.spec is ItemizedSpec
                ? l10n.itemsEdit
                : l10n.itemsOpen,
            onTap: _openItems,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        actions: [
          SplitStatusLine(spec: spec, amount: amount, problem: problem),
          const SizedBox(height: AppSpacing.md),
          LoadingButton(
            label: l10n.doneButton,
            onPressed: problem == null ? () => context.pop(spec) : null,
          ),
        ],
      ),
    );
  }
}

/// "Ali (you)" for you, the plain name for everyone else.
String memberName(AppLocalizations l10n, Member m, String meId) =>
    m.id == meId ? l10n.memberYou(m.displayName) : m.displayName;

/// Equal mode: tick who was there; their part shows under the name.
class _TickRow extends StatelessWidget {
  const _TickRow({
    required this.member,
    required this.meId,
    required this.ticked,
    required this.owes,
    required this.onChanged,
  });

  final Member member;
  final String meId;
  final bool ticked;
  final int? owes;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CheckboxListTile(
      value: ticked,
      onChanged: (on) => onChanged(on ?? false),
      secondary: MemberAvatar(
        name: member.displayName,
        placeholder: member.isPlaceholder,
      ),
      title: Text(memberName(l10n, member, meId)),
      subtitle: owes == null ? null : Text(formatRupees(owes!)),
    );
  }
}

/// Exact / %: a number per person at the end of the row.
class SplitInputRow extends StatelessWidget {
  const SplitInputRow({
    super.key,
    required this.member,
    required this.meId,
    required this.mode,
    required this.controller,
    required this.owes,
  });

  final Member member;
  final String meId;
  final SplitMode mode;
  final TextEditingController controller;

  /// Rupees this works out to (%), or null.
  final int? owes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: MemberAvatar(
        name: member.displayName,
        placeholder: member.isPlaceholder,
      ),
      title: Text(memberName(l10n, member, meId)),
      subtitle: owes == null ? null : Text(formatRupees(owes!)),
      trailing: UnitNumberField(
        controller: controller,
        percent: mode == SplitMode.percent,
      ),
    );
  }
}

/// A small number box with its unit always showing: "Rs 300" or "16 %".
/// (InputDecoration's prefix/suffix text hides while the box is empty,
/// which made a bare "0" look like rupees, and doubled up with a "0%"
/// hint once focused.)
class UnitNumberField extends StatelessWidget {
  const UnitNumberField({
    super.key,
    required this.controller,
    this.percent = false,
  });

  final TextEditingController controller;
  final bool percent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unit = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        percent ? l10n.percentSuffix : l10n.currencyPrefix,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    const fit = BoxConstraints();
    return SizedBox(
      width: AppSizes.splitInputWidth,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          percent ? PercentInputFormatter() : RupeeInputFormatter(),
        ],
        textAlign: TextAlign.end,
        textInputAction: TextInputAction.next,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: '0',
          prefixIcon: percent ? null : unit,
          prefixIconConstraints: fit,
          suffixIcon: percent ? unit : null,
          suffixIconConstraints: fit,
        ),
      ),
    );
  }
}

/// The live line above Done: what's left, what's too much, or that it
/// adds up (DESIGN.md §11). Over-assigning is the only error.
class SplitStatusLine extends StatelessWidget {
  const SplitStatusLine({
    required this.spec,
    required this.amount,
    required this.problem,
  });

  final SplitSpec spec;
  final int? amount;
  final SplitProblem? problem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final over = switch (problem) {
      RupeesLeft(:final paisa) => paisa < 0,
      PercentLeft(:final basisPoints) => basisPoints < 0,
      _ => false,
    };
    final text = problem != null
        ? splitProblemText(l10n, problem!)
        : splitStatusText(l10n, spec, amount);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: over
            ? theme.colorScheme.error
            : problem == null
            ? context.extraColors.settled
            : muted,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Digits and one dot, at most 2 decimals, at most 100.
class PercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d{1,3}(\.\d{0,2})?$').hasMatch(text)) return oldValue;
    final bp = parsePercent(text);
    return bp == null ? oldValue : newValue;
  }
}

/// "Split a bill by items ›" under the members: a quiet teal link to the
/// itemized screen (owner, 2026-11-20: its own screen, not a 5th tab).
class _ItemsLink extends StatelessWidget {
  const _ItemsLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final link = context.extraColors.link;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: link),
                  ),
                ),
                Icon(Icons.chevron_right, color: link),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
