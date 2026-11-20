import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/expense.dart';
import '../domain/split_spec.dart';
import 'split_screen.dart';

/// What Add expense hands the payers screen.
class PayersArgs {
  const PayersArgs({
    required this.amount,
    required this.meId,
    required this.payers,
  });

  /// Paisa, or null if the amount isn't entered yet.
  final int? amount;
  final String meId;

  /// What's entered so far (memberId → paisa).
  final Map<String, int> payers;
}

/// "More than one person" paid (PLAN.md §3 item 7): an amount per person,
/// the same live "Rs X left" line as the split screen, Done only when it
/// adds up to the total. Pops with `{memberId: paisa}` (zeros left out).
class PayersScreen extends ConsumerStatefulWidget {
  const PayersScreen({super.key, required this.groupId, required this.args});

  final String groupId;
  final PayersArgs args;

  @override
  ConsumerState<PayersScreen> createState() => _PayersScreenState();
}

class _PayersScreenState extends ConsumerState<PayersScreen> {
  final _fields = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(String id) =>
      _fields[id] ??= TextEditingController(
        text: switch (widget.args.payers[id]) {
          final p? when p > 0 => RupeeInputFormatter.textFor(p),
          _ => '',
        },
      )..addListener(() => setState(() {}));

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
    final paid = ExactSpec({
      for (final m in members) m.id: parseRupees(_field(m.id).text) ?? 0,
    });
    final problem = paid.problem(amount);
    final result = {
      for (final e in paid.amounts.entries)
        if (e.value > 0) e.key: e.value,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          amount == null || amount == 0
              ? l10n.whoPaidTitle
              : l10n.payersTitleAmount(formatRupees(amount)),
        ),
      ),
      body: ScreenLayout(
        padded: false,
        pinned: true,
        body: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.screenHorizontal + AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.payersHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Panel(
            dividerIndent: avatarRowDividerIndent,
            children: [
              for (final m in members)
                SplitInputRow(
                  member: m,
                  meId: widget.args.meId,
                  mode: SplitMode.exact,
                  controller: _field(m.id),
                  owes: null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        actions: [
          SplitStatusLine(spec: paid, amount: amount, problem: problem),
          const SizedBox(height: AppSpacing.md),
          LoadingButton(
            label: l10n.doneButton,
            onPressed: problem == null ? () => context.pop(result) : null,
          ),
        ],
      ),
    );
  }
}
