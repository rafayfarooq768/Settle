import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_provider.dart';
import '../data/settlement_repository.dart';
import '../domain/settlement.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => SettlementRepository(ref.watch(firestoreProvider)),
);

final settlementsProvider = StreamProvider.autoDispose
    .family<List<Settlement>, String>(
      (ref, groupId) => ref.watch(settlementRepositoryProvider).watch(groupId),
    );
