import 'package:supabase_flutter/supabase_flutter.dart';

class AcademicsRepository {
  AcademicsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> years() async =>
      (await _client.from('academic_years').select().order('start_date', ascending: false))
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> terms(String yearId) async =>
      (await _client.from('terms').select().eq('academic_year_id', yearId).order('start_date'))
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> classes() async =>
      (await _client.from('classes').select().order('numeric_level')).cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> sections({String? campusId}) async {
    var q = _client.from('sections').select('*, classes(name)');
    if (campusId != null) q = q.eq('campus_id', campusId);
    final rows = await q.order('name');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> subjects() async =>
      (await _client.from('subjects').select().order('name')).cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> holidays() async =>
      (await _client.from('holidays').select().order('holiday_date', ascending: false))
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> gradingScales() async =>
      (await _client.from('grading_scales').select()).cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> staff({String? campusId}) async {
    var q = _client.from('staff').select().eq('status', 'ACTIVE');
    if (campusId != null) q = q.eq('campus_id', campusId);
    final rows = await q.order('full_name');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> assignments({String? yearId, String? campusId}) async {
    var q = _client.from('teacher_assignments').select(
        '*, staff(full_name), classes(name), sections(name), subjects(name), academic_years(name), terms(name)');
    if (yearId != null) q = q.eq('academic_year_id', yearId);
    if (campusId != null) q = q.eq('campus_id', campusId);
    return (await q.order('created_at', ascending: false)).cast<Map<String, dynamic>>();
  }

  Future<void> insert(String table, Map<String, dynamic> values) =>
      _client.from(table).insert(values);

  Future<void> update(String table, String id, Map<String, dynamic> values) =>
      _client.from(table).update(values).eq('id', id);

  Future<void> delete(String table, String id) => _client.from(table).delete().eq('id', id);

  // ---- Timetable ----
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

  Future<void> clearSectionWeek({required String yearId, required String sectionId, String? termId}) async {
    var q = _client.from('timetable_slots').delete().eq('academic_year_id', yearId).eq('section_id', sectionId);
    if (termId != null) q = q.eq('term_id', termId);
    await q;
  }

  // ---- Homework ----
  Future<List<Map<String, dynamic>>> homework({String? sectionId, String? staffId}) async {
    var q = _client.from('homework').select(
        '*, subjects(name), sections(name), classes(name), staff(full_name)');
    if (sectionId != null) q = q.eq('section_id', sectionId);
    if (staffId != null) q = q.eq('staff_id', staffId);
    return (await q.order('assigned_on', ascending: false).limit(100)).cast<Map<String, dynamic>>();
  }

  Future<void> addHomework(Map<String, dynamic> values) => _client.from('homework').insert(values);

  Future<void> updateHomework(String id, Map<String, dynamic> values) =>
      _client.from('homework').update(values).eq('id', id);
}
