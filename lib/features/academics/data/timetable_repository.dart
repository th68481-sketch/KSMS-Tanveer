import 'package:supabase_flutter/supabase_flutter.dart';

class TimetableRepository {
  TimetableRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> timetableSlots({
    required String yearId,
    String? termId,
    String? sectionId,
  }) async {
    var q = _client.from('timetable_slots').select(
        '*, staff(full_name), subjects(name), sections(name), classes(name)');
    q = q.eq('academic_year_id', yearId);
    if (termId != null) q = q.eq('term_id', termId);
    if (sectionId != null) q = q.eq('section_id', sectionId);
    return (await q.order('period')).cast<Map<String, dynamic>>();
  }

  Future<void> addSlot(Map<String, dynamic> values) => _client.from('timetable_slots').insert(values);
  
  Future<void> deleteSlot(String id) => _client.from('timetable_slots').delete().eq('id', id);

  Future<void> clearSectionWeek({required String yearId, required String sectionId, String? termId}) async {
    var q = _client.from('timetable_slots').delete().eq('academic_year_id', yearId).eq('section_id', sectionId);
    if (termId != null) q = q.eq('term_id', termId);
    await q;
  }
  
  Future<Map<String, dynamic>> checkConflict(Map<String, dynamic> slot) async {
    return await _client.rpc('check_timetable_conflict', params: slot).single();
  }
}
