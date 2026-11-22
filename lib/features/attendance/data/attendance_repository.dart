import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceRepository {
  AttendanceRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listSessions({
    required String tenantId,
    required String campusId,
    required String sectionId,
    required String academicYearId,
  }) async {
    return await _client
        .from('attendance_sessions')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('section_id', sectionId)
        .eq('academic_year_id', academicYearId)
        .order('session_date', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getRecordsForSession(String sessionId) async {
    return await _client
        .from('attendance_records')
        .select('*, students(full_name)')
        .eq('session_id', sessionId);
  }

  Future<Map<String, dynamic>> createSession({
    required Map<String, dynamic> session,
  }) async {
    return await _client
        .from('attendance_sessions')
        .insert(session)
        .select()
        .single();
  }

  Future<void> updateSessionStatus(String sessionId, String status) async {
    await _client
        .from('attendance_sessions')
        .update({'status': status, 'locked_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);
  }

  Future<void> upsertRecords({
    required List<Map<String, dynamic>> records,
  }) async {
    // For bulk upserts in Supabase, we can use the insert method with onConflict
    await _client.from('attendance_records').upsert(
      records,
      onConflict: 'session_id,student_id',
    );
  }
}
