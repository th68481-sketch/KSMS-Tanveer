import 'package:supabase_flutter/supabase_flutter.dart';

class ExamsRepository {
  ExamsRepository(this._client);
  final SupabaseClient _client;

  // Exams
  Future<List<Map<String, dynamic>>> exams({String? termId}) async {
    var q = _client.from('exams').select('*, terms(name), subjects(name)');
    if (termId != null) q = q.eq('term_id', termId);
    return (await q.order('date')).cast<Map<String, dynamic>>();
  }

  Future<void> upsertExam(Map<String, dynamic> values) => _client.from('exams').upsert(values);
  Future<void> deleteExam(String id) => _client.from('exams').delete().eq('id', id);

  // Marks
  Future<List<Map<String, dynamic>>> marks({String? examId}) async {
    var q = _client.from('marks').select('*, students(full_name, roll_number)');
    if (examId != null) q = q.eq('exam_id', examId);
    return (await q).cast<Map<String, dynamic>>();
  }

  Future<void> upsertMarks(List<Map<String, dynamic>> values) => _client.from('marks').upsert(values);

  // Amendments
  Future<List<Map<String, dynamic>>> amendments({String? examId}) async {
    var q = _client.from('amendments').select('*, exams(name)');
    if (examId != null) q = q.eq('exam_id', examId);
    return (await q.order('created_at', ascending: false)).cast<Map<String, dynamic>>();
  }

  Future<void> createAmendment(Map<String, dynamic> values) => _client.from('amendments').insert(values);

  // RPC Wrappers
  Future<void> publishExam(String examId) => _client.rpc('publish_exam', params: {'exam_id': examId});
  Future<void> amendMarks(String markId, double newMarks, String reason) => 
      _client.rpc('amend_marks', params: {'mark_id': markId, 'new_marks': newMarks, 'reason': reason});
}
