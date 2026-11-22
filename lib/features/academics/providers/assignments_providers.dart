import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../auth/providers/session_controller.dart';
import '../data/assignments_repository.dart';
import 'academics_providers.dart';

final assignmentsRepositoryProvider =
    Provider<AssignmentsRepository>((ref) => AssignmentsRepository(ref.watch(supabaseProvider)));

final assignmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  final year = ref.watch(currentYearProvider);
  return ref.watch(assignmentsRepositoryProvider).assignments(
        yearId: year?['id'] as String?,
        campusId: session?.activeCampusId,
      );
});
