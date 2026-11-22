import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksms/core/network/supabase_providers.dart';
import 'package:ksms/features/portal/data/portal_repository.dart';

final portalRepositoryProvider = Provider<PortalRepository>((ref) {
  return PortalRepository(ref.watch(supabaseProvider));
});
