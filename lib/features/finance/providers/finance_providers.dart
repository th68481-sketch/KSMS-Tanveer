import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../data/finance_repository.dart';

final financeRepositoryProvider =
    Provider<FinanceRepository>((ref) => FinanceRepository(ref.watch(supabaseProvider)));

final feeHeadsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, tenantId) {
  return ref.watch(financeRepositoryProvider).listFeeHeads(tenantId);
});

final invoicesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, tenantId) {
  return ref.watch(financeRepositoryProvider).listInvoices(tenantId);
});

final expensesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, tenantId) {
  return ref.watch(financeRepositoryProvider).listExpenses(tenantId);
});
