import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../data/homework_repository.dart';

final homeworkRepositoryProvider =
    Provider<HomeworkRepository>((ref) => HomeworkRepository(ref.watch(supabaseProvider)));

final homeworkProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String? sectionId, String? staffId})>((ref, p) {
  return ref.watch(homeworkRepositoryProvider).homework(sectionId: p.sectionId, staffId: p.staffId);
});
