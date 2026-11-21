import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/session_controller.dart';
import '../../../core/network/supabase_providers.dart';

class DashboardKpis {
  DashboardKpis(this.values);
  final Map<String, int> values;

  int operator [](String key) => values[key] ?? 0;
}

Future<int> _count(SupabaseClient c, String table, Map<String, Object?> filters) async {
  var q = c.from(table).select('id');
  filters.forEach((k, v) {
    if (v != null) q = q.eq(k, v);
  });
  final rows = await q;
  return rows.length;
}

/// School/campus dashboard KPIs — all computed from authorized rows.
final schoolDashboardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String tenantId, String? campusId})>(
  (ref, scope) async {
    final c = ref.watch(supabaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    var studentQ = c.from('students').select('id').eq('status', 'ACTIVE');
    var staffQ = c.from('staff').select('id').eq('status', 'ACTIVE');
    if (scope.campusId != null) {
      studentQ = studentQ.eq('campus_id', scope.campusId!);
      staffQ = staffQ.eq('campus_id', scope.campusId!);
    }

    final results = await Future.wait<dynamic>([
      studentQ,
      staffQ,
      // Sessions today
      (() async {
        var q = c.from('attendance_sessions').select('id').eq('session_date', today);
        if (scope.campusId != null) q = q.eq('campus_id', scope.campusId!);
        final sessions = await q;
        if ((sessions as List).isEmpty) return {'total': 0, 'present': 0};
        var rq = c.from('attendance_records').select('status');
        if (scope.campusId != null) rq = rq.eq('campus_id', scope.campusId!);
        final records = await rq;
        final list = records.cast<Map<String, dynamic>>();
        return {
          'total': list.length,
          'present': list.where((r) => r['status'] == 'PRESENT').length,
        };
      })(),
      // Fees due
      (() async {
        var q = c.from('invoices').select('gross_total,discount_total,paid_total');
        if (scope.campusId != null) q = q.eq('campus_id', scope.campusId!);
        final rows = (await q).cast<Map<String, dynamic>>();
        double due = 0;
        for (final r in rows) {
          final gross = (r['gross_total'] as num?) ?? 0;
          final disc = (r['discount_total'] as num?) ?? 0;
          final paid = (r['paid_total'] as num?) ?? 0;
          final balance = gross - disc - paid;
          if (balance > 0) due += balance;
        }
        return {'due': due};
      })(),
      _count(c, 'leave_requests', {'status': 'PENDING'}),
      _count(c, 'homework', {'status': 'PUBLISHED', 'due_on': today}),
    ]);

    final attendance = results[2] as Map<String, dynamic>;
    final fees = results[3] as Map<String, dynamic>;

    return {
      'students': (results[0] as List).length,
      'staff': (results[1] as List).length,
      'attendanceTotal': attendance['total'] as int,
      'attendancePresent': attendance['present'] as int,
      'feesDue': fees['due'] as double,
      'pendingLeaves': results[4] as int,
      'homeworkDueToday': results[5] as int,
    };
  },
);

/// Platform Super Admin dashboard.
final platformDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final c = ref.watch(supabaseProvider);
  final tenants = await c.from('tenants').select('id,type,status');
  final campuses = await c.from('campuses').select('id');
  final pending = await c
      .from('access_requests')
      .select('id')
      .inFilter('state', ['REQUESTED', 'PENDING_REVIEW', 'NEEDS_INFORMATION']);
  final audit = await c
      .from('audit_events')
      .select('id,action,entity,created_at,actor')
      .order('created_at', ascending: false)
      .limit(8);

  final list = tenants.cast<Map<String, dynamic>>();
  return {
    'private': list.where((t) => t['type'] == 'PRIVATE').length,
    'government': list.where((t) => t['type'] == 'GOVERNMENT').length,
    'suspended': list.where((t) => t['status'] == 'SUSPENDED').length,
    'campuses': (campuses as List).length,
    'pendingRequests': (pending as List).length,
    'recentAudit': audit.cast<Map<String, dynamic>>(),
  };
});

/// Government Authority dashboard.
final govDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final c = ref.watch(supabaseProvider);
  final tenants =
      await c.from('tenants').select('id,name,city,semis_code,gov_district,status').eq('type', 'GOVERNMENT');
  final list = tenants.cast<Map<String, dynamic>>();
  final ids = list.map((t) => t['id'] as String).toList();

  int students = 0;
  int pendingRequests = 0;
  if (ids.isNotEmpty) {
    final enrolls = await c.from('enrollments').select('id').inFilter('tenant_id', ids).eq('status', 'ACTIVE');
    students = (enrolls as List).length;
    final reqs = await c
        .from('access_requests')
        .select('id')
        .inFilter('state', ['REQUESTED', 'PENDING_REVIEW', 'NEEDS_INFORMATION']);
    pendingRequests = (reqs as List).length;
  }

  return {
    'schools': list.length,
    'students': students,
    'pendingRequests': pendingRequests,
    'schoolsList': list,
  };
});

final dashboardScopeProvider = Provider<({String tenantId, String? campusId})?>((ref) {
  final s = ref.watch(sessionProvider).valueOrNull;
  if (s == null || !s.isSchoolUser) return null;
  final tenant = s.activeTenantId;
  if (tenant == null) return null;
  return (tenantId: tenant, campusId: s.activeCampusId);
});
