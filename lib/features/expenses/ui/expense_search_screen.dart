import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/ui/groups_providers.dart';
import '../../settlements/ui/settlements_providers.dart';
import '../domain/expense.dart';
import '../domain/expense_search.dart';
import 'expense_list.dart';
import 'expenses_providers.dart';

/// Search a group's expenses (PLAN.md §3 item 7): words in the title or
/// note, plus two filters, "Involves me" and a month. Results use the same
/// day panels and rows as the Expenses tab.
class ExpenseSearchScreen extends ConsumerStatefulWidget {
  const ExpenseSearchScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<ExpenseSearchScreen> createState() =>
      _ExpenseSearchScreenState();
}

class _ExpenseSearchScreenState extends ConsumerState<ExpenseSearchScreen> {
  final _query = TextEditingController();
  bool _mine = false;
  DateTime? _month;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _pickMonth(List<DateTime> months) async {
    final l10n = AppLocalizations.of(context)!;
    final format = DateFormat.yMMMM(l10n.localeName);
    // A record so "Any month" (null) differs from dismissing the sheet.
    final picked = await showAppSheet<({DateTime? month})>(
      context: context,
      scrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            SheetTitle(l10n.filterMonth),
            for (final m in [null, ...months])
              ListTile(
                minTileHeight: AppSpacing.rowHeight,
                title: Text(m == null ? l10n.filterAnyMonth : format.format(m)),
                trailing: m == _month ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheet).pop((month: m)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _month = picked.month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final me = ref.watch(myMemberProvider(widget.groupId)).valueOrNull;
    final members = ref.watch(membersProvider(widget.groupId)).valueOrNull;
    final expenses =
        ref.watch(expensesProvider(widget.groupId)).valueOrNull ?? const [];
    final settlements =
        ref.watch(settlementsProvider(widget.groupId)).valueOrNull ?? const [];
    final months = expenseMonths(expenses);
    final format = DateFormat.yMMMM(l10n.localeName);

    bool keep(Expense e) => matchesSearch(
      e,
      query: _query.text,
      involving: _mine ? me?.id : null,
      month: _month,
    );
    final any = expenses.any(keep);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              tooltip: l10n.clearSearchTooltip,
              icon: const Icon(Icons.close),
              onPressed: () => setState(_query.clear),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              0,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChip(
                  label: Text(l10n.filterInvolvesMe),
                  selected: _mine,
                  onSelected: (v) => setState(() => _mine = v),
                ),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _month == null
                            ? l10n.filterMonth
                            : format.format(_month!),
                      ),
                      // Drawn full size but takes no height, so this chip
                      // is exactly as tall as "Involves me" (the icon is a
                      // pixel taller than the text line).
                      const SizedBox(
                        width: AppSizes.buttonIcon,
                        height: 0,
                        child: OverflowBox(
                          maxHeight: AppSizes.buttonIcon,
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: AppSizes.buttonIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                  selected: _month != null,
                  showCheckmark: false,
                  onSelected: (_) => _pickMonth(months),
                ),
              ],
            ),
          ),
          Expanded(
            child: members == null || me == null
                ? const Center(child: CircularProgressIndicator())
                : any
                ? ExpenseList(
                    expenses: expenses,
                    settlements: settlements,
                    members: members,
                    meId: me.id,
                    where: keep,
                    onOpen: (e) => context.push(
                      '/groups/${widget.groupId}/expenses/${e.id}',
                    ),
                  )
                : TabMessage(l10n.searchNoResults),
          ),
        ],
      ),
    );
  }
}
