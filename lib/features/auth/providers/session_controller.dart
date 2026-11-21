import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/domain.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../core/offline/sync_engine.dart';

enum SessionPhase { loading, signedOut, pendingApproval, mfaRequired, active }

class MembershipContext {
  MembershipContext({
    required this.membershipId,
    required this.roleKey,
    this.tenantId,
    this.campusId,
    this.scopes = const {},
    this.expiresAt,
  });

  final String membershipId;
  final String roleKey;
  final String? tenantId;
  final String? campusId;
  final Map<String, dynamic> scopes;
  final DateTime? expiresAt;

  bool get isActivePlatform => roleKey == UserRole.platformSuperAdmin.key;
  bool get isGovAdmin => roleKey == UserRole.governmentAuthorityAdmin.key;

  static MembershipContext fromJson(Map<String, dynamic> j) => MembershipContext(
        membershipId: j['membership_id'] as String,
        roleKey: (j['role_key'] as String?) ?? '',
        tenantId: j['tenant_id'] as String?,
        campusId: j['campus_id'] as String?,
        scopes: Map<String, dynamic>.from((j['scopes'] as Map?) ?? {}),
        expiresAt: j['expires_at'] == null ? null : DateTime.parse(j['expires_at'] as String),
      );
}

class TenantSummary {
  TenantSummary({required this.id, required this.name, required this.type, required this.status});
  final String id;
  final String name;
  final TenantType type;
  final String status;
}

class CampusSummary {
  CampusSummary({required this.id, required this.tenantId, required this.name, required this.code});
  final String id;
  final String tenantId;
  final String name;
  final String code;
}

class SessionState {
  const SessionState({
    required this.phase,
    this.profile = const {},
    this.permissions = const {},
    this.memberships = const [],
    this.tenants = const [],
    this.campuses = const [],
    this.activeTenantId,
    this.activeCampusId,
    this.error,
  });

  final SessionPhase phase;
  final Map<String, dynamic> profile;
  final Set<String> permissions;
  final List<MembershipContext> memberships;
  final List<TenantSummary> tenants;
  final List<CampusSummary> campuses;
  final String? activeTenantId;
  final String? activeCampusId;
  final String? error;

  UserRole? get primaryRole {
    for (final r in const [
      UserRole.platformSuperAdmin,
      UserRole.governmentAuthorityAdmin,
      UserRole.tenantAdmin,
      UserRole.principal,
      UserRole.vicePrincipal,
      UserRole.registrar,
      UserRole.accountant,
      UserRole.hrOfficer,
      UserRole.opsOfficer,
      UserRole.teacher,
      UserRole.auditor,
      UserRole.parent,
      UserRole.student,
    ]) {
      if (memberships.any((m) => m.roleKey == r.key)) return r;
    }
    return null;
  }

  bool get isPlatformAdmin => memberships.any((m) => m.isActivePlatform);
  bool get isGovAdmin => memberships.any((m) => m.isGovAdmin);
  bool get isSchoolUser =>
      memberships.any((m) => m.tenantId != null && !m.isGovAdmin);

  bool can(String permission) => permissions.contains(permission);

  TenantSummary? get activeTenant =>
      tenants.where((t) => t.id == activeTenantId).firstOrNull;

  List<CampusSummary> get activeCampuses =>
      campuses.where((c) => c.tenantId == activeTenantId).toList();

  SessionState copyWith({
    SessionPhase? phase,
    Map<String, dynamic>? profile,
    Set<String>? permissions,
    List<MembershipContext>? memberships,
    List<TenantSummary>? tenants,
    List<CampusSummary>? campuses,
    String? activeTenantId,
    String? activeCampusId,
    String? error,
    bool clearTenant = false,
    bool clearCampus = false,
  }) =>
      SessionState(
        phase: phase ?? this.phase,
        profile: profile ?? this.profile,
        permissions: permissions ?? this.permissions,
        memberships: memberships ?? this.memberships,
        tenants: tenants ?? this.tenants,
        campuses: campuses ?? this.campuses,
        activeTenantId: clearTenant ? null : (activeTenantId ?? this.activeTenantId),
        activeCampusId: clearCampus ? null : (activeCampusId ?? this.activeCampusId),
        error: error,
      );
}

class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final client = ref.watch(supabaseProvider);
    final session = client.auth.currentSession;
    final authSub = client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(() => authSub.cancel());
    if (session == null) {
      return const SessionState(phase: SessionPhase.signedOut);
    }
    return _loadFor(client.auth.currentUser!.id);
  }

  Future<SessionState> _loadFor(String userId) async {
    final client = ref.read(supabaseProvider);
    try {
      final ctx = await client.schema('app').rpc('my_context') as Map<String, dynamic>;

      final memberships = ((ctx['memberships'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(MembershipContext.fromJson)
          .where((m) => m.roleKey.isNotEmpty)
          .toList();

      final permissions = ((ctx['permissions'] as List?) ?? const [])
          .cast<String>()
          .toSet();

      if (memberships.isEmpty) {
        return SessionState(phase: SessionPhase.pendingApproval, profile: _asMap(ctx['profile']), permissions: permissions);
      }

      // Activate any invited memberships now that the user has signed in.
      try {
        await client.schema('app').rpc('activate_my_memberships');
      } catch (_) {}

      final tenants = await _loadTenants(client, memberships);
      final campuses = await _loadCampuses(client, tenants);

      // MFA enforcement for privileged roles
      final needsMfa = memberships.any((m) => mfaRequiredRoles.contains(m.roleKey));
      if (needsMfa) {
        final factors = await client.auth.mfa.listFactors();
        final verified = factors.all.any((f) => f.status == 'verified');
        if (!verified) {
          return SessionState(
            phase: SessionPhase.mfaRequired,
            profile: _asMap(ctx['profile']),
            permissions: permissions,
            memberships: memberships,
            tenants: tenants,
            campuses: campuses,
          );
        }
      }

      final tenantIds = memberships.map((m) => m.tenantId).whereType<String>().toSet();
      final storedTenant = tenants
          .where((t) => tenantIds.contains(t.id) || (t.id.isEmpty && memberships.any((m) => m.isActivePlatform)))
          .firstOrNull;
      final activeTenantId = storedTenant?.id ??
          (tenants.isNotEmpty
              ? tenants.first.id
              : (memberships.any((m) => m.isActivePlatform) ? '' : null));
      final campusList = campuses.where((c) => c.tenantId == activeTenantId).toList();

      return SessionState(
        phase: SessionPhase.active,
        profile: _asMap(ctx['profile']),
        permissions: permissions,
        memberships: memberships,
        tenants: tenants,
        campuses: campuses,
        activeTenantId: (activeTenantId == null || activeTenantId.isEmpty) ? null : activeTenantId,
        activeCampusId: campusList.isNotEmpty ? campusList.first.id : null,
      );
    } catch (e) {
      return SessionState(phase: SessionPhase.loading, error: e.toString());
    }
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  Future<List<TenantSummary>> _loadTenants(
      SupabaseClient client, List<MembershipContext> memberships) async {
    final ids = memberships.map((m) => m.tenantId).whereType<String>().toSet().toList();
    if (ids.isEmpty) return const [];
    final rows =
        await client.from('tenants').select('id,name,type,status').inFilter('id', ids);
    return rows.map<TenantSummary>((r) => TenantSummary(
          id: r['id'] as String,
          name: (r['name'] as String?) ?? '',
          type: TenantTypeX.from((r['type'] as String?) ?? 'PRIVATE'),
          status: (r['status'] as String?) ?? 'ACTIVE',
        )).toList();
  }

  Future<List<CampusSummary>> _loadCampuses(
      SupabaseClient client, List<TenantSummary> tenants) async {
    if (tenants.isEmpty) return const [];
    final rows = await client
        .from('campuses')
        .select('id,tenant_id,campus_code,name')
        .inFilter('tenant_id', tenants.map((t) => t.id).toList());
    return rows.map<CampusSummary>((r) => CampusSummary(
          id: r['id'] as String,
          tenantId: r['tenant_id'] as String,
          name: (r['name'] as String?) ?? '',
          code: (r['campus_code'] as String?) ?? '',
        )).toList();
  }

  Future<void> switchTenant(String tenantId) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final campuses = s.campuses.where((c) => c.tenantId == tenantId).toList();
    state = AsyncValue.data(s.copyWith(
      activeTenantId: tenantId,
      activeCampusId: campuses.isNotEmpty ? campuses.first.id : null,
    ));
  }

  Future<void> switchCampus(String? campusId) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncValue.data(s.copyWith(activeCampusId: campusId));
  }

  Future<void> refreshContext() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadFor(Supabase.instance.client.auth.currentUser!.id));
  }

  Future<void> signOut() async {
    await ref.read(supabaseProvider).auth.signOut();
    ref.invalidate(syncEngineProvider);
    state = const AsyncValue.data(SessionState(phase: SessionPhase.signedOut));
  }

  Future<void> markMfaConfigured() => refreshContext();
}

/// Permission check helper: `ref.watch(canProvider(Permissions.studentsRead))`.
final canProvider = Provider.family<bool, String>((ref, permission) {
  return ref.watch(sessionProvider).valueOrNull?.can(permission) ?? false;
});

final sessionProvider =
    AsyncNotifierProvider<SessionController, SessionState>(SessionController.new);
