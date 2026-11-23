import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';

class ApprovalRepository {
  ApprovalRepository(this._client);
  final SupabaseClient _client;

  Future<List>> listRequests({String? state, String? kind}) async {
    var q = _client.from('access_requests').select();
    if (kind != null && kind != 'ALL') q = q.eq('kind', kind);
    final rows = await q.order('submitted_at', ascending: false).limit(200);
    final list = List.of(rows).map((e) => Map.of(e as Map)).cast>().toList();
    if (state == null || state == 'ALL') return list;
    if (state == 'PENDING_REVIEW') {
      return list.where((r) {
        final st = (r['state'] ?? r['status'] ?? '').toString().toUpperCase();
        return st == 'PENDING_REVIEW' || st == 'REQUESTED' || st == 'SUBMITTED' || st == 'PENDING';
      }).toList();
    }
    return list.where((r) {
      final st = (r['state'] ?? r['status'] ?? '').toString().toUpperCase();
      return st == state.toUpperCase();
    }).toList();
  }

  Future<List>> listActions(String requestId) async {
    final rows = await _client
        .from('approval_actions')
        .select()
        .eq('access_request_id', requestId)
        .order('created_at');
    return rows.cast>();
  }

  /// Decision runs through the trusted Edge Function which validates the
  /// caller's permissions, records the append-only approval action,
  /// provisions tenants/memberships and dispatches invitations.
  Future?> decide({
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

  Future<void> deleteRequest(String requestId) async {
    await _client.from('access_requests').delete().eq('id', requestId);
  }

  Future<void> directStateUpdate(String requestId, String nextState, String reason) async {
    await _client.from('access_requests').update({
      'state': nextState,
      'decision_reason': reason,
    }).eq('id', requestId);
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
    .family<List>, String>((ref, state) {
  return ref.watch(approvalRepositoryProvider).listRequests(state: state);
});
