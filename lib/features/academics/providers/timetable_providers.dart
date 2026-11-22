import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../data/timetable_repository.dart';

final timetableRepositoryProvider =
    Provider<TimetableRepository>((ref) => TimetableRepository(ref.watch(supabaseProvider)));

final timetableSlotsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String yearId, String? termId, String? sectionId})>(
  (ref, p) {
    return ref
        .watch(timetableRepositoryProvider)
        .timetableSlots(yearId: p.yearId, termId: p.termId, sectionId: p.sectionId);
  },
);
