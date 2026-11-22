import 'package:supabase_flutter/supabase_flutter.dart';

class HomeworkRepository {
  HomeworkRepository(this._client);
  final SupabaseClient _client;

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
