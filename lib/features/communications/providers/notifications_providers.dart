import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realtime_client/realtime_client.dart';

import '../../../core/network/supabase_providers.dart';

/// In-app notifications with realtime updates for the signed-in user.
class NotificationsController
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final client = ref.watch(supabaseProvider);
    final user = client.auth.currentUser;
    if (user == null) return const [];

    // Realtime push (RLS restricts rows to the owner automatically).
    _channel = client
        .channel('notifications:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'user_id', value: user.id),
          callback: (payload) {
            final row = Map<String, dynamic>.from(payload.newRecord);
            state = state.whenData((rows) => [row, ...rows]);
          },
        )
        .subscribe();
    ref.onDispose(() {
      client.removeChannel(_channel!);
      _channel = null;
    });

    final rows = await client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> markRead(String id) async {
    final client = ref.read(supabaseProvider);
    await client.from('notifications').update({'read_at': DateTime.now().toIso8601String()}).eq('id', id);
    state = state.whenData((rows) =>
        rows.map((r) => r['id'] == id ? {...r, 'read_at': DateTime.now().toIso8601String()} : r).toList());
  }

  Future<void> markAllRead() async {
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    if (user == null) return;
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', user.id)
        .filter('read_at', 'is', null);
    ref.invalidateSelf();
  }
}

final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsController, List<Map<String, dynamic>>>(
  NotificationsController.new,
);

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final rows = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return rows.where((r) => r['read_at'] == null).length;
});
