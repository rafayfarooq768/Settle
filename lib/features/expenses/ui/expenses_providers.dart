import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_provider.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(firestoreProvider)),
);

/// All expenses of a group, while its screen is open.
final expensesProvider = StreamProvider.autoDispose
    .family<List<Expense>, String>(
      (ref, groupId) => ref.watch(expenseRepositoryProvider).watch(groupId),
    );
