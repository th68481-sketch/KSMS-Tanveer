import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../network/supabase_providers.dart';
import 'queue_store.dart';

enum SyncPhase { idle, syncing, offline, error }

class SyncConflict {
  SyncConflict({
    required this.operationId,
    required this.message,
    this.serverRecords = const [],
  });

  final String operationId;
  final String message;
  final List<Map<String, dynamic>> serverRecords;
}

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastError,
    this.conflicts = const [],
    this.lastSyncedAt,
  });

  final SyncPhase phase;
  final int pendingCount;
  final String? lastError;
  final List<SyncConflict> conflicts;
  final DateTime? lastSyncedAt;

  bool get hasConflicts => conflicts.isNotEmpty;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    String? lastError,
    List<SyncConflict>? conflicts,
    DateTime? lastSyncedAt,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        pendingCount: pendingCount ?? this.pendingCount,
        lastError: lastError,
        conflicts: conflicts ?? this.conflicts,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

/// Offline-first sync engine.
///
/// Mutations collected while offline are stored in the encrypted queue and
/// flushed through the trusted `attendance-sync` Edge Function which is
/// idempotent per `operation_uuid` and resolves version conflicts explicitly.
class SyncEngine extends Notifier<SyncStatus> {
  static const _uuid = Uuid();

  @override
  SyncStatus build() {
    ref.listen(queueStoreProvider, (_, next) {
      next.whenData((store) {
        _pendingCount = store.length;
        state = state.copyWith(pendingCount: _pendingCount);
      });
    });
    ref.listen(connectivityStreamProvider, (_, next) {
      next.whenData((online) {
        if (online && _pendingCount > 0) flush();
      });
    });
    return const SyncStatus();
  }

  int _pendingCount = 0;

  Future<void> enqueueAttendanceBatch({
    required String tenantId,
    required String campusId,
    required String classId,
    required String sectionId,
    required String academicYearId,
    required String sessionDate,
    required String sessionKind,
    required List<Map<String, dynamic>> records,
  }) async {
    final store = await ref.read(queueStoreProvider.future);
    await store.enqueue(QueueEntry(
      id: _uuid.v4(),
      kind: 'ATTENDANCE_BATCH',
      createdAt: DateTime.now(),
      payload: {
        'tenant_id': tenantId,
        'campus_id': campusId,
        'class_id': classId,
        'section_id': sectionId,
        'academic_year_id': academicYearId,
        'session_date': sessionDate,
        'session_kind': sessionKind,
        'records': records,
      },
    ));
    _pendingCount = store.length;
    state = state.copyWith(pendingCount: _pendingCount);
    await flush();
  }

  Future<void> flush() async {
    if (state.phase == SyncPhase.syncing) return;
    final store = await ref.read(queueStoreProvider.future);
    if (store.length == 0) {
      _pendingCount = 0;
      state = SyncStatus(lastSyncedAt: state.lastSyncedAt);
      return;
    }
    state = state.copyWith(phase: SyncPhase.syncing);
    final client = ref.read(supabaseProvider);

    for (final entry in List.of(store.entries)) {
      try {
        final res = await client.functions.invoke('attendance-sync', body: {
          'operations': [entry.toJson()],
        });
        final data = res.data;
        if (data is! Map) {
          await store.markAttempt(entry.id, 'Malformed edge function response');
          state = state.copyWith(phase: SyncPhase.error, lastError: 'Malformed response');
          return;
        }
        final results = (data['results'] as List?) ?? const [];
        for (final r in results) {
          final status = (r as Map)['status'] as String?;
          if (status == 'PROCESSED') {
            await store.remove(entry.id);
            ref.read(onSyncCompleteListenerProvider)?.call();
          } else if (status == 'CONFLICT') {
            final conflicts = [
              SyncConflict(
                operationId: entry.id,
                message: (r['message'] as String?) ?? 'Version conflict on the server',
                serverRecords:
                    ((r['conflicts'] as List?) ?? const []).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
              )
            ];
            await store.markAttempt(entry.id, 'CONFLICT');
            state = state.copyWith(phase: SyncPhase.error, conflicts: conflicts);
            return;
          } else {
            await store.markAttempt(entry.id, (r['message'] as String?) ?? 'Rejected');
            state = state.copyWith(phase: SyncPhase.error, lastError: 'Operation rejected');
            return;
          }
        }
      } catch (e) {
        await store.markAttempt(entry.id, e.toString());
        state = state.copyWith(phase: SyncPhase.offline, lastError: e.toString());
        return; // stay queued; retried on next connectivity event
      }
    }
    _pendingCount = store.length;
    state = state.copyWith(
      phase: _pendingCount > 0 ? SyncPhase.error : SyncPhase.idle,
      pendingCount: _pendingCount,
      lastSyncedAt: DateTime.now(),
      conflicts: const [],
    );
  }

  /// Resolve a conflict by keeping the server copy (drop queued op).
  Future<void> discardConflict(String operationId) async {
    final store = await ref.read(queueStoreProvider.future);
    await store.remove(operationId);
    _pendingCount = store.length;
    state = SyncStatus(pendingCount: _pendingCount, lastSyncedAt: state.lastSyncedAt);
  }

  /// Resolve a conflict by force-applying the local values with a bumped
  /// version and a mandatory reason (audited server-side).
  Future<void> forceApplyConflict({
    required String operationId,
    required String reason,
  }) async {
    final store = await ref.read(queueStoreProvider.future);
    final entry = store.entries.where((e) => e.id == operationId).firstOrNull;
    if (entry == null) return;
    final payload = Map<String, dynamic>.from(entry.payload);
    final client = ref.read(supabaseProvider);
    try {
      final res = await client.functions.invoke('attendance-sync', body: {
        'operations': [
          {...entry.toJson(), 'force': true, 'reason': reason, 'payload': payload}
        ],
      });
      final data = res.data;
      final ok = data is Map && (data['results'] as List?)?.firstOrNull is Map &&
          ((data['results'] as List).first as Map)['status'] == 'PROCESSED';
      if (ok) {
        await store.remove(operationId);
        ref.read(onSyncCompleteListenerProvider)?.call();
      }
    } catch (e) {
      state = state.copyWith(phase: SyncPhase.error, lastError: e.toString());
      return;
    }
    _pendingCount = store.length;
    state = SyncStatus(pendingCount: _pendingCount, lastSyncedAt: DateTime.now());
  }
}

/// Callback hook: features register to refresh data after a successful sync.
final onSyncCompleteListenerProvider =
    StateProvider<void Function()?>((ref) => null);

final syncEngineProvider =
    NotifierProvider<SyncEngine, SyncStatus>(SyncEngine.new);
