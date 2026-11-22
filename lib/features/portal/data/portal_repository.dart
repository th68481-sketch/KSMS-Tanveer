import 'package:supabase_flutter/supabase_flutter.dart';

class PortalRepository {
  PortalRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getAttendance(String studentId) async {
    final rows = await _client
        .from('attendance')
        .select('*, enrollments(student_id)')
        .eq('enrollments.student_id', studentId)
        .order('date', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getHomework(String studentId) async {
    final rows = await _client
        .from('homework')
        .select('*, enrollments(student_id)')
        .eq('enrollments.student_id', studentId)
        .order('due_date', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }
}
