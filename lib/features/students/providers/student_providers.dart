import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../data/student_repository.dart';

final studentRepositoryProvider =
    Provider<StudentRepository>((ref) => StudentRepository(ref.watch(supabaseProvider)));

/// Directory rows joined with the active enrollment.
final studentListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String tenantId, String? campusId, String? sectionId})>(
  (ref, scope) {
    return ref.watch(studentRepositoryProvider).listStudents(
          tenantId: scope.tenantId,
          campusId: scope.campusId,
          sectionId: scope.sectionId,
        );
  },
);

final studentDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, studentId) {
  return ref.watch(studentRepositoryProvider).getStudent(studentId);
});

final studentEnrollmentsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(studentRepositoryProvider).enrollmentsOf(id);
});

final studentGuardiansProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(studentRepositoryProvider).guardiansOf(id);
});

final studentAttendanceSummaryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(studentRepositoryProvider).attendanceSummary(id);
});

final studentInvoicesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(studentRepositoryProvider).invoicesOf(id);
});

final studentReportCardsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(studentRepositoryProvider).reportCardsOf(id);
});

final studentDocumentsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(studentRepositoryProvider).documentsOf(id);
});
