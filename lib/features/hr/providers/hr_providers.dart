import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksms/core/network/supabase_providers.dart';
import 'package:ksms/features/hr/data/hr_repository.dart';

final hrRepositoryProvider = Provider<HrRepository>((ref) {
  return HrRepository(ref.watch(supabaseProvider));
});
