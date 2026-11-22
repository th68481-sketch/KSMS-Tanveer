import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/attendance_repository.dart';
import '../../../core/network/supabase_providers.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(supabaseProvider));
});

final attendanceSessionsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({
  String tenantId,
  String campusId,
  String sectionId,
  String academicYearId,
})>((ref, params) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.listSessions(
    tenantId: params.tenantId,
    campusId: params.campusId,
    sectionId: params.sectionId,
    academicYearId: params.academicYearId,
  );
});

final attendanceRecordsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sessionId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getRecordsForSession(sessionId);
});
