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

  Future<void> insert(String table, Map<String, dynamic> values) =>
      _client.from(table).insert(values);

  Future<void> update(String table, String id, Map<String, dynamic> values) =>
      _client.from(table).update(values).eq('id', id);

  Future<void> delete(String table, String id) => _client.from(table).delete().eq('id', id);
}
