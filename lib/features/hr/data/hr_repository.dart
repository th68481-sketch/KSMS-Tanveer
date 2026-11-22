import 'package:supabase_flutter/supabase_flutter.dart';

class HrRepository {
  HrRepository(this._client);
  final SupabaseClient _client;

  // Staff Attendance
  Future<List<Map<String, dynamic>>> getStaffAttendance(String tenantId, String campusId, DateTime date) async {
    final rows = await _client
        .from('staff_attendance')
        .select('*, staff(full_name)')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('work_date', date.toIso8601String().split('T')[0]);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> logStaffAttendance(Map<String, dynamic> values) async {
    await _client.from('staff_attendance').upsert(values);
  }

  // Leave Requests
  Future<List<Map<String, dynamic>>> getLeaveRequests(String tenantId, String campusId) async {
    final rows = await _client
        .from('leave_requests')
        .select('*, staff(full_name)')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> submitLeaveRequest(Map<String, dynamic> values) async {
    await _client.from('leave_requests').insert(values);
  }

  // Payroll
  Future<List<Map<String, dynamic>>> getPayrollRuns(String tenantId, String campusId) async {
    final rows = await _client
        .from('payroll_runs')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }
}
