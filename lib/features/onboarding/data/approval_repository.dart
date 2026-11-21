import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';

class ApprovalRepository {
  ApprovalRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listRequests({String? state, String? kind}) async {
    var q = _client.from('access_requests').select();
    if (state != null && state != 'ALL') q = q.eq('state', state);
    if (kind != null && kind != 'ALL') q = q.eq('kind', kind);
    final rows = await q.order('submitted_at', ascending: false).limit(200);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listActions(String requestId) async {
    final rows = await _client
        .from('approval_actions')
        .select()
        .eq('access_request_id', requestId)
        .order('created_at');
    return rows.cast<Map<String, dynamic>>();
  }

  /// Decision runs through the trusted Edge Function which validates the
  /// caller's permissions, records the append-only approval action,
  /// provisions tenants/memberships and dispatches invitations.
  Future<Map<String, dynamic>?> decide({
    required String requestId,
    required String decision,
    required String reason,
  }) async {
    final res = await _client.functions.invoke('provision-approval', body: {
      'request_id': requestId,
      'decision': decision,
      'reason': reason,
    });
    return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
  }

  /// Signed URLs for evidence review (private bucket).
  Future<List<String>> evidenceUrls(List<String> paths) async {
    final urls = <String>[];
    for (final p in paths) {
      try {
        urls.add(await _client.storage.from('private-documents').createSignedUrl(p, 300));
      } catch (_) {}
    }
    return urls;
  }
}

final approvalRepositoryProvider =
    Provider<ApprovalRepository>((ref) => ApprovalRepository(ref.watch(supabaseProvider)));

final approvalQueueProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, state) {
  return ref.watch(approvalRepositoryProvider).listRequests(state: state);
});
