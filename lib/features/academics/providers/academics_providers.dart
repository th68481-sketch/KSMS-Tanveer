import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../auth/providers/session_controller.dart';
import '../data/academics_repository.dart';

final academicsRepositoryProvider =
    Provider<AcademicsRepository>((ref) => AcademicsRepository(ref.watch(supabaseProvider)));

final academicYearsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(academicsRepositoryProvider).years();
});

final currentYearProvider = Provider<Map<String, dynamic>?>((ref) {
  final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
  return years.where((y) => y['is_current'] == true).firstOrNull ?? years.firstOrNull;
});

final termsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, yearId) {
  return ref.watch(academicsRepositoryProvider).terms(yearId);
});

final classesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(academicsRepositoryProvider).classes();
});

final sectionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  return ref.watch(academicsRepositoryProvider).sections(campusId: session?.activeCampusId);
});

final subjectsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(academicsRepositoryProvider).subjects();
});

final holidaysProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(academicsRepositoryProvider).holidays();
});

final gradingScalesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(academicsRepositoryProvider).gradingScales();
});

final staffListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  return ref.watch(academicsRepositoryProvider).staff(campusId: session?.activeCampusId);
});

final assignmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  final year = ref.watch(currentYearProvider);
  return ref.watch(academicsRepositoryProvider).assignments(
        yearId: year?['id'] as String?,
        campusId: session?.activeCampusId,
      );
});

final timetableSlotsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String yearId, String? termId, String? sectionId})>(
  (ref, p) {
    return ref
        .watch(academicsRepositoryProvider)
        .timetableSlots(yearId: p.yearId, termId: p.termId, sectionId: p.sectionId);
  },
);

final homeworkProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String? sectionId, String? staffId})>((ref, p) {
  return ref.watch(academicsRepositoryProvider).homework(sectionId: p.sectionId, staffId: p.staffId);
});
