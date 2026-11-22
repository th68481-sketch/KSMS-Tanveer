import 'package:supabase_flutter/supabase_flutter.dart';

class AuditRepository {
  AuditRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getAuditLogs(String tenantId) async {
    final rows = await _client
        .from('audit_events')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.cast<Map<String, dynamic>>();
  }
}
