import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksms/core/network/supabase_providers.dart';
import 'package:ksms/features/audit/data/audit_repository.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(supabaseProvider));
});
