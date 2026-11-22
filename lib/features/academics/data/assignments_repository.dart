import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentsRepository {
  AssignmentsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> assignments({String? yearId, String? campusId}) async {
    var q = _client.from('teacher_assignments').select(
        '*, staff(full_name), classes(name), sections(name), subjects(name), academic_years(name), terms(name)');
    if (yearId != null) q = q.eq('academic_year_id', yearId);
    if (campusId != null) q = q.eq('campus_id', campusId);
    return (await q.order('created_at', ascending: false)).cast<Map<String, dynamic>>();
  }

  Future<void> insert(Map<String, dynamic> values) =>
      _client.from('teacher_assignments').insert(values);

  Future<void> update(String id, Map<String, dynamic> values) =>
      _client.from('teacher_assignments').update(values).eq('id', id);

  Future<void> delete(String id) => _client.from('teacher_assignments').delete().eq('id', id);
}
