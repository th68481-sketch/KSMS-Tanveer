import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication & onboarding repository.
/// All privileged operations (provisioning, invitations) happen in Edge
/// Functions; this repository only performs allowed client actions.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);

  /// Public (possibly anonymous) school registration request.
  Future<String> submitSchoolRegistration({
    required String institutionName,
    required String institutionType,
    required String campusName,
    required String city,
    String? semisCode,
    required String requesterName,
    required String requesterEmail,
    required String requesterPhone,
    String? notes,
  }) async {
    final isSignedIn = _client.auth.currentUser != null;
    final row = {
      'kind': 'SCHOOL_REGISTRATION',
      'institution_name': institutionName,
      'institution_type': institutionType,
      'campus_name': campusName,
      'city': city,
      if (semisCode != null && semisCode.isNotEmpty) 'semis_code': semisCode,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'requester_phone': requesterPhone,
      'details': {'notes': notes ?? ''},
      if (isSignedIn) 'requester_user_id': _client.auth.currentUser!.id,
    };
    final res = await _client.from('access_requests').insert(row).select('id').single();
    return res['id'] as String;
  }

  /// Staff access request targeting an existing tenant.
  Future<String> submitStaffAccess({
    required String tenantId,
    required String campusId,
    required String requestedRole,
    required String requesterName,
    required String requesterEmail,
    required String requesterPhone,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    final row = {
      'kind': 'STAFF_ACCESS',
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'requester_phone': requesterPhone,
      'requested_role': requestedRole,
      'target_tenant_id': tenantId,
      'target_campus_id': campusId,
      'details': {'notes': notes ?? ''},
      if (user != null) 'requester_user_id': user.id,
    };
    final res = await _client.from('access_requests').insert(row).select('id').single();
    return res['id'] as String;
  }

  /// Upload evidence documents to the private bucket (anonymously allowed
  /// for fresh registration requests; authenticated requesters also fine).
  Future<List<String>> uploadEvidence(String requestId, List<UploadedFile> files) async {
    final paths = <String>[];
    for (final f in files) {
      final path = 'ar/$requestId/${f.name}';
      final isAnon = _client.auth.currentUser == null;
      await _client.storage.from('private-documents').uploadBinary(
            path,
            Uint8List.fromList(f.bytes),
            fileOptions: FileOptions(
              contentType: f.contentType,
              upsert: true,
            ),
          );
      paths.add(path);
      // Record metadata (allowed only for signed-in users; anonymous
      // requesters' evidence is referenced via the request evidence_paths).
      if (!isAnon) {
        try {
          await _client.from('documents').insert({
            'owner_kind': 'ACCESS_REQUEST',
            'owner_id': requestId,
            'path': path,
            'filename': f.name,
            'mime_type': f.contentType,
            'size_bytes': f.bytes.length,
          });
        } catch (_) {
          // Metadata is best-effort; the object itself remains in the bucket.
        }
      }
    }
    if (paths.isNotEmpty) {
      await _client
          .from('access_requests')
          .update({'evidence_paths': paths}).eq('id', requestId);
    }
    return paths;
  }

  Future<Map<String, dynamic>?> checkStatus(String reference, String email) async {
    final res = await _client.schema('app').rpc(
          'check_status',
          params: {'p_reference': reference.trim().toUpperCase(), 'p_email': email.trim()},
        );
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  Future<List<Map<String, dynamic>>> lookupTenants(String query) async {
    final res = await _client.schema('app').rpc('public_tenant_lookup',
        params: {'p_query': query});
    return (res as List).cast<Map<String, dynamic>>();
  }

  // --- MFA (TOTP) ---
  Future<AuthMFAEnrollResponse> enrollMfa() =>
      _client.auth.mfa.enroll(factorType: FactorType.totp, friendlyName: 'KSMS Authenticator');

  Future<bool> verifyMfa(String factorId, String code) async {
    final challenge = await _client.auth.mfa.challenge(factorId: factorId);
    await _client.auth.mfa.verify(factorId: factorId, challengeId: challenge.id, code: code);
    return true;
  }

  Future<void> updateProfile({String? fullName, String? locale, String? phone}) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (locale != null) 'locale': locale,
      if (phone != null) 'phone': phone,
    }).eq('id', uid);
  }
}

class UploadedFile {
  UploadedFile({required this.name, required this.bytes, this.contentType = 'application/octet-stream'});
  final String name;
  final List<int> bytes;
  final String contentType;
}
