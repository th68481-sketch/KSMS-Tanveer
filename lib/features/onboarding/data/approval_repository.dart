import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_providers.dart';

class ApprovalRepository {
  ApprovalRepository(this._client);
  final SupabaseClient _client;

  Future listRequests({var state, var kind}) async {
    var q = _client.from('access_requests').select();
    if (kind != null && kind != 'ALL') q = q.eq('kind', kind);
    final rows = await q.order('submitted_at', ascending: false).limit(200);
    final list = List.of(rows).map((e) => Map.of(e as Map)).toList();
    if (state == null || state == 'ALL') return list;
    if (state == 'PENDING_REVIEW') {
      return list.where((r) {
        final st = (r['state'] ?? r['status'] ?? '').toString().toUpperCase();
        return st == 'PENDING_REVIEW' || st == 'REQUESTED' || st == 'SUBMITTED' || st == 'PENDING';
      }).toList();
    }
    return list.where((r) {
      final st = (r['state'] ?? r['status'] ?? '').toString().toUpperCase();
      return st == state.toString().toUpperCase();
    }).toList();
  }

  Future listActions(var requestId) async {
    final rows = await _client.from('approval_actions').select().eq('access_request_id', requestId).order('created_at');
    return List.of(rows);
  }

  Future decide({required var requestId, required var decision, required var reason}) async {
    final res = await _client.functions.invoke('provision-approval', body: {'request_id': requestId, 'decision': decision, 'reason': reason});
    return res.data is Map ? Map.of(res.data as Map) : null;
  }

  Future deleteRequest(var requestId) async {
    await _client.from('access_requests').delete().eq('id', requestId);
  }

  Future directStateUpdate(var requestId, var nextState, var reason) async {
    await _client.from('access_requests').update({'state': nextState, 'decision_reason': reason}).eq('id', requestId);
  }

  Future evidenceUrls(var paths) async {
    final urls = [];
    for (final p in paths) {
      try { urls.add(await _client.storage.from('private-documents').createSignedUrl(p.toString(), 300)); } catch (_) {}
    }
    return urls;
  }
}

final approvalRepositoryProvider = Provider((ref) => ApprovalRepository(ref.watch(supabaseProvider)));
final approvalQueueProvider = FutureProvider.autoDispose.family((ref, state) => ref.watch(approvalRepositoryProvider).listRequests(state: state));
