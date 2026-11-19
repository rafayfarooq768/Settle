import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../expenses/ui/expenses_providers.dart';
import '../../groups/ui/groups_providers.dart';
import '../../settlements/ui/settlements_providers.dart';

/// memberId → net paisa for a group, computed every time from expenses and
/// confirmed settlements (PLAN.md §4: balances are never stored).
/// Deleted expenses and ones whose numbers don't add up are left out.
final groupNetsProvider = Provider.autoDispose
    .family<AsyncValue<Map<String, int>>, String>((ref, groupId) {
      final expenses = ref.watch(expensesProvider(groupId));
      final settlements = ref.watch(settlementsProvider(groupId));
      final members = ref.watch(membersProvider(groupId));

      for (final value in [expenses, settlements, members]) {
        if (value.hasError) {
          return AsyncError(value.error!, value.stackTrace!);
        }
      }
      if (!expenses.hasValue || !settlements.hasValue || !members.hasValue) {
        return const AsyncLoading();
      }
      try {
        return AsyncData(
          netBalances(
            expenses: [
              for (final e in expenses.requireValue)
                if (!e.deleted && e.isBalanced) e.toLedger(),
            ],
            settlements: [
              for (final s in settlements.requireValue)
                if (s.isConfirmed) s.toLedger(),
            ],
            members: [for (final m in members.requireValue) m.id],
          ),
        );
      } on MoneyException catch (e, st) {
        return AsyncError(e, st);
      }
    });

/// The signed-in user's net in one group (0 until they pick their member).
final myGroupNetProvider = Provider.autoDispose.family<AsyncValue<int>, String>(
  (ref, groupId) {
    final me = ref.watch(myMemberProvider(groupId));
    final nets = ref.watch(groupNetsProvider(groupId));
    if (me.hasError) return AsyncError(me.error!, me.stackTrace!);
    if (nets.hasError) return AsyncError(nets.error!, nets.stackTrace!);
    if (!me.hasValue || !nets.hasValue) return const AsyncLoading();
    final id = me.requireValue?.id;
    return AsyncData(id == null ? 0 : nets.requireValue[id] ?? 0);
  },
);
