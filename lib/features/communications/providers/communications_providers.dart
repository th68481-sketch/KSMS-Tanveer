import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksms/core/network/supabase_providers.dart';
import 'package:ksms/features/communications/data/communications_repository.dart';

final communicationsRepositoryProvider = Provider<CommunicationsRepository>((ref) {
  return CommunicationsRepository(ref.watch(supabaseProvider));
});
