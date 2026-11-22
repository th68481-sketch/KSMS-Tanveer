import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  ReportsRepository(this._client);
  final SupabaseClient _client;

  Future<void> logExport(String tenantId, String entity, Map<String, dynamic> details) async {
    await _client.schema('app').rpc('log_export', params: {
      'p_tenant': tenantId,
      'p_entity': entity,
      'p_details': details,
    });
  }
}
