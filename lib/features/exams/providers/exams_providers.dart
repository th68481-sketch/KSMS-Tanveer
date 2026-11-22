import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../data/exams_repository.dart';

final examsRepositoryProvider =
    Provider<ExamsRepository>((ref) => ExamsRepository(ref.watch(supabaseProvider)));

final examsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>((ref, termId) {
  return ref.watch(examsRepositoryProvider).exams(termId: termId);
});

final marksProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, examId) {
  return ref.watch(examsRepositoryProvider).marks(examId: examId);
});

final amendmentsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, examId) {
  return ref.watch(examsRepositoryProvider).amendments(examId: examId);
});
