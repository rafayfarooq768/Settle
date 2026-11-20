import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../../profile/ui/profile_providers.dart';
import '../domain/expense.dart';
import '../domain/expense_summary.dart';
import 'day_label.dart';
import 'expense_pickers.dart';
import 'expenses_providers.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/select_field.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Add expense (DESIGN.md §11): amount → title → paid by → split → Save.
/// The common case is 3 taps (PLAN.md §2): paid by defaults to you and
/// everyone is ticked. Equal split only for now (step 5). Works offline.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  String? _payerId;
  Set<String>? _participants;
  DateTime _day = DateTime.now();
  String? _amountError;
  String? _titleError;
  String? _splitError;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Keeps "Rs X each" up to date while typing.
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickPayer(List<Member> members, String meId) async {
    final picked = await pickPayer(
      context,
      members: members,
      meId: meId,
      selected: _payerId ?? meId,
    );
    if (picked != null) setState(() => _payerId = picked);
  }

  Future<void> _pickParticipants(List<Member> members, String meId) async {
    final picked = await pickParticipants(
      context,
      members: members,
      meId: meId,
      selected: _participants ?? {for (final m in members) m.id},
    );
    if (picked != null) {
      setState(() {
        _participants = picked;
        _splitError = null;
      });
    }
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _save(List<Member> members, Member me) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = parseRupees(_amount.text);
    final title = _title.text.trim();
    final participants = [
      for (final m in members)
        if ((_participants ?? {for (final m in members) m.id}).contains(m.id))
          m.id,
    ];
    setState(() {
      _amountError = amount == null || amount == 0
          ? l10n.errorAmountRequired
          : amount > maxExpenseAmount
          ? l10n.errorAmountTooLarge
          : null;
      _titleError = title.isEmpty ? l10n.errorExpenseTitleRequired : null;
      _splitError = participants.isEmpty ? l10n.errorPickSomeone : null;
      _error = null;
    });
    if (_amountError != null || _titleError != null || _splitError != null) {
      return;
    }

    final identity = ref.read(myIdentityProvider);
    if (identity == null) return;
    final now = DateTime.now();
    // The picked day, at the current time, so same-day expenses stay in
    // the order they were added.
    final date = DateTime(
      _day.year,
      _day.month,
      _day.day,
      now.hour,
      now.minute,
      now.second,
    );
    final draft = equalDraft(
      title: title,
      amount: amount!,
      date: date,
      payerId: _payerId ?? me.id,
      participants: participants,
    );

    setState(() => _saving = true);
    final repo = ref.read(expenseRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await repo.add(
        groupId: widget.groupId,
        uid: identity.uid,
        actorMemberId: me.id,
        draft: draft,
      );
      final added = Expense(
        id: id,
        title: draft.title,
        amount: draft.amount,
        date: draft.date,
        createdBy: identity.uid,
        createdAt: now,
        updatedAt: now,
        splitMode: draft.splitMode,
        payers: draft.payers,
        shares: draft.shares,
        splitInput: draft.splitInput,
      );
      messenger.showMessage(
        l10n.expenseAdded,
        undoLabel: l10n.undoButton,
        // The screen is gone by then, so use the repo captured above.
        onUndo: () => repo.setDeleted(
          groupId: widget.groupId,
          actorMemberId: me.id,
          expense: added,
          deleted: true,
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final me = ref.watch(myMemberProvider(widget.groupId)).valueOrNull;
    final members =
        (ref.watch(membersProvider(widget.groupId)).valueOrNull ??
                const <Member>[])
            .where((m) => m.active)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addExpenseTitle)),
      body: me == null
          ? const Center(child: CircularProgressIndicator())
          : ScreenLayout(
              body: [
                const SizedBox(height: AppSpacing.xl),
                AmountField(
                  controller: _amount,
                  label: l10n.amountLabel,
                  prefix: l10n.currencyPrefix,
                  error: _amountError,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _title,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.expenseTitleLabel,
                    hintText: l10n.expenseTitleHint,
                    errorText: _titleError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Details(
                  members: members,
                  me: me,
                  payerId: _payerId ?? me.id,
                  participants:
                      _participants ?? {for (final m in members) m.id},
                  amount: parseRupees(_amount.text),
                  day: _day,
                  splitError: _splitError,
                  onPayer: () => _pickPayer(members, me.id),
                  onSplit: () => _pickParticipants(members, me.id),
                  onDay: _pickDay,
                ),
              ],
              actions: [
                if (_error != null) ...[
                  FormMessage(_error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                LoadingButton(
                  label: l10n.saveButton,
                  isLoading: _saving,
                  onPressed: () => _save(members, me),
                ),
              ],
            ),
    );
  }
}

/// Paid by, Split and Date as select fields, each opening a picker.
class _Details extends StatelessWidget {
  const _Details({
    required this.members,
    required this.me,
    required this.payerId,
    required this.participants,
    required this.amount,
    required this.day,
    required this.splitError,
    required this.onPayer,
    required this.onSplit,
    required this.onDay,
  });

  final List<Member> members;
  final Member me;
  final String payerId;
  final Set<String> participants;
  final int? amount;
  final DateTime day;
  final String? splitError;
  final VoidCallback onPayer;
  final VoidCallback onSplit;
  final VoidCallback onDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payer = members.where((m) => m.id == payerId).firstOrNull;
    final payerName = payerId == me.id
        ? l10n.youLabel
        : payer?.displayName ?? '';
    final count = members.where((m) => participants.contains(m.id)).length;
    final each = amount != null && amount! > 0 && count > 0
        ? l10n.splitEach(formatRupees(amount! ~/ count))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectField(
          label: l10n.paidByRow,
          value: payerName,
          leading: MemberAvatar(
            name: payer?.displayName ?? me.displayName,
            placeholder: payer?.isPlaceholder ?? false,
            size: AppSizes.avatarSmall,
          ),
          onTap: onPayer,
        ),
        const SizedBox(height: AppSpacing.lg),
        SelectField(
          label: l10n.splitRow,
          value: l10n.splitEqually(count),
          leading: const Icon(Icons.group_outlined),
          helper: each,
          error: splitError,
          onTap: onSplit,
        ),
        const SizedBox(height: AppSpacing.lg),
        SelectField(
          label: l10n.dateRow,
          value: dayLabel(l10n, day),
          leading: const Icon(Icons.calendar_today_outlined),
          onTap: onDay,
        ),
      ],
    );
  }
}
