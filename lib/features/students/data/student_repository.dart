import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StudentRepository {
  StudentRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listStudents({
    required String tenantId,
    String? campusId,
    String? sectionId,
    int limit = 500,
  }) async {
    var q = _client.from('students').select(
        'id, tenant_id, campus_id, admission_no, full_name, gender, date_of_birth, status, b_form_no, photo_path,'
        ' enrollments(id, roll_no, status, class_id, section_id, academic_year_id, classes(name), sections(name))');
    q = q.eq('tenant_id', tenantId);
    if (campusId != null) q = q.eq('campus_id', campusId);
    final rows = await q.order('full_name').limit(limit);
    final list = rows.cast<Map<String, dynamic>>();
    if (sectionId != null) {
      return list.where((s) {
        final enrolls = (s['enrollments'] as List?) ?? const [];
        return enrolls.any((e) => (e as Map)['section_id'] == sectionId && e['status'] == 'ACTIVE');
      }).toList();
    }
    return list;
  }

  Future<Map<String, dynamic>?> getStudent(String id) async {
    final rows = await _client.from('students').select('*').eq('id', id).limit(1);
    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> enrollmentsOf(String studentId) async {
    final rows = await _client
        .from('enrollments')
        .select('*, classes(name), sections(name), academic_years(name)')
        .eq('student_id', studentId)
        .order('admission_date', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> guardiansOf(String studentId) async {
    final rows = await _client
        .from('student_guardians')
        .select('*, guardians(full_name, phone, cnic, email)')
        .eq('student_id', studentId);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> attendanceSummary(String studentId) async {
    final rows = await _client
        .from('attendance_student_monthly')
        .select()
        .eq('student_id', studentId)
        .order('month', ascending: false)
        .limit(6);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> invoicesOf(String studentId) async {
    final rows = await _client
        .from('invoices')
        .select('id, invoice_no, billing_period, issue_date, due_date, status, gross_total, discount_total, paid_total')
        .eq('student_id', studentId)
        .order('issue_date', ascending: false)
        .limit(24);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> reportCardsOf(String studentId) async {
    final rows = await _client
        .from('report_cards')
        .select('*, exams(name), enrollments(class_id, classes(name))')
        .eq('enrollments.student_id', studentId)
        .order('published_at', ascending: false)
        .limit(12);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> documentsOf(String studentId) async {
    final rows = await _client
        .from('documents')
        .select()
        .eq('owner_kind', 'STUDENT')
        .eq('owner_id', studentId)
        .order('uploaded_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> findDuplicates({
    required String tenantId,
    required String name,
    String? dob,
    String? bForm,
  }) async {
    final res = await _client.schema('app').rpc('find_duplicate_students', params: {
      'p_tenant': tenantId,
      'p_name': name,
      'p_dob': dob,
      'p_b_form': bForm,
    });
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> merge(String keepId, String duplicateId) =>
      _client.schema('app').rpc('merge_students', params: {
        'p_keep': keepId,
        'p_duplicate': duplicateId,
      });

  Future<String> createStudent(Map<String, dynamic> values) async {
    final res = await _client.from('students').insert(values).select('id').single();
    return res['id'] as String;
  }

  Future<void> updateStudent(String id, Map<String, dynamic> values) =>
      _client.from('students').update(values).eq('id', id);

  Future<void> createEnrollment({
    required String tenantId,
    required String campusId,
    required String studentId,
    required String yearId,
    required String classId,
    required String sectionId,
    int? rollNo,
  }) async {
    await _client.from('enrollments').insert({
      'tenant_id': tenantId,
      'campus_id': campusId,
      'student_id': studentId,
      'academic_year_id': yearId,
      'class_id': classId,
      'section_id': sectionId,
      if (rollNo != null) 'roll_no': rollNo,
    });
  }

  Future<void> linkGuardian({
    required String tenantId,
    required String studentId,
    required String guardianName,
    required String phone,
    String? cnic,
    required String relationship,
    required bool isPrimary,
    required bool canPickup,
    required bool portalAccess,
  }) async {
    final existing = await _client
        .from('guardians')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('phone', phone)
        .limit(1);
    String guardianId;
    if ((existing as List).isNotEmpty) {
      guardianId = (existing.first as Map)['id'] as String;
    } else {
      final created = await _client
          .from('guardians')
          .insert({
            'tenant_id': tenantId,
            'full_name': guardianName,
            'phone': phone,
            if (cnic != null && cnic.isNotEmpty) 'cnic': cnic,
          })
          .select('id')
          .single();
      guardianId = created['id'] as String;
    }
    await _client.from('student_guardians').upsert({
      'tenant_id': tenantId,
      'student_id': studentId,
      'guardian_id': guardianId,
      'relationship': relationship,
      'is_primary': isPrimary,
      'can_pickup': canPickup,
      'portal_access': portalAccess,
      'verification_method': 'IN_PERSON',
      'verified': true,
    }, onConflict: 'student_id,guardian_id');
  }

  Future<String> promote({
    required String toYear,
    required String toClass,
    required String toSection,
    required List<String> enrollmentIds,
  }) async {
    final res = await _client.schema('app').rpc('promote_students', params: {
      'p_to_year': toYear,
      'p_to_class': toClass,
      'p_to_section': toSection,
      'p_from_enrollments': enrollmentIds,
    });
    return (res as int? ?? 0).toString();
  }

  Future<String> issueLeavingCertificate({
    required String enrollmentId,
    required String finalStatus,
    required String reason,
  }) async {
    final res = await _client.schema('app').rpc('issue_leaving_certificate', params: {
      'p_enrollment': enrollmentId,
      'p_final_status': finalStatus,
      'p_reason': reason,
    });
    return res as String;
  }

  Future<void> uploadStudentDocument({
    required String tenantId,
    String? campusId,
    required String studentId,
    required String filename,
    required List<int> bytes,
    required String contentType,
  }) async {
    final path = 'tenants/$tenantId/students/$studentId/$filename';
    await _client.storage.from('private-documents').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    await _client.from('documents').insert({
      'tenant_id': tenantId,
      'campus_id': campusId,
      'owner_kind': 'STUDENT',
      'owner_id': studentId,
      'path': path,
      'filename': filename,
      'mime_type': contentType,
      'size_bytes': bytes.length,
    });
  }

  Future<String> documentUrl(String path) =>
      _client.storage.from('private-documents').createSignedUrl(path, 300);
}
