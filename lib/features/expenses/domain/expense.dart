import '../../../core/money/money.dart';

/// How the shares were produced. Balance math never looks at this
/// (PLAN.md §4); it's kept so the expense can be edited in the same mode.
/// Shares (units per person) was removed by the owner on 2026-11-20; an
/// old expense saved that way still counts (its shares are stored).
enum SplitMode { equal, exact, percent, itemized }

/// `groups/{groupId}/expenses/{expenseId}` (PLAN.md §7). Amounts are paisa.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.splitMode,
    required this.payers,
    required this.shares,
    this.splitInput = const {},
    this.note = '',
    this.deleted = false,
    this.pendingSync = false,
  });

  final String id;
  final String title;
  final int amount;
  final DateTime date;

  /// uid of the person who added it.
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SplitMode splitMode;

  /// memberId → paisa paid. Sums to [amount].
  final Map<String, int> payers;

  /// memberId → paisa owed. Sums to [amount].
  final Map<String, int> shares;

  /// Raw split input (ticked members, exact amounts, %, units, items).
  final Map<String, Object?> splitInput;
  final String note;

  /// Soft delete: deleted expenses stay for the activity log and Undo.
  final bool deleted;

  /// Saved on this phone but not on the server yet (offline), so the
  /// rest of the group can't see it yet.
  final bool pendingSync;

  LedgerExpense toLedger() =>
      LedgerExpense(amount: amount, payers: payers, shares: shares);

  /// False if stored data breaks the money rules (rules can't check sums).
  /// Such expenses are left out of balances instead of breaking them.
  bool get isBalanced {
    try {
      toLedger().validate();
      return true;
    } on MoneyException {
      return false;
    }
  }
}
