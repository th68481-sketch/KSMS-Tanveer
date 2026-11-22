import 'package:supabase_flutter/supabase_flutter.dart';

class CommunicationsRepository {
  CommunicationsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getNotices(String tenantId) async {
    final rows = await _client
        .from('notices')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('published_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> publishNotice(Map<String, dynamic> values) async {
    await _client.schema('app').rpc('publish_notice', params: values);
  }
}
