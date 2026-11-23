import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/providers/session_controller.dart';
import '../../features/auth/ui/mfa_setup_screen.dart';
import '../../features/auth/ui/pending_screen.dart';
import '../../features/auth/ui/profile_screen.dart';
import '../../features/auth/ui/request_access_screen.dart';
import '../../features/auth/ui/sign_in_screen.dart';
import '../../features/auth/ui/status_check_screen.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../core/theme/design_tokens.dart';
import '../../features/onboarding/ui/approval_queue_screen.dart';
import '../../features/students/ui/student_directory_screen.dart';
import '../../features/students/ui/student_profile_screen.dart';
import '../../features/academics/ui/academic_setup_screen.dart';
import '../utils/formatters.dart';
import '../../features/communications/providers/notifications_providers.dart';
import '../widgets/async_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionAsync = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      return sessionAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (session) {
          final loc = state.matchedLocation;
          final isAuthRoute = loc == Routes.welcome ||
              loc == Routes.signIn ||
              loc == Routes.requestAccess ||
              loc == Routes.statusCheck;

          if (session.phase == SessionPhase.signedOut) {
            return isAuthRoute ? null : Routes.signIn;
          }
          if (session.phase == SessionPhase.pendingApproval) {
            return loc == Routes.pending ? null : Routes.pending;
          }
          if (session.phase == SessionPhase.mfaRequired) {
            return isAuthRoute ? Routes.dashboard : null;
          }
          if (isAuthRoute || loc == Routes.pending || loc == Routes.mfaSetup) {
            return Routes.dashboard;
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: Routes.welcome, builder: (_, __) => const SignInScreen()),
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(path: Routes.requestAccess, builder: (_, __) => const RequestAccessScreen()),
      GoRoute(path: Routes.statusCheck, builder: (_, __) => const StatusCheckScreen()),
      GoRoute(path: Routes.pending, builder: (_, __) => const PendingScreen()),
      GoRoute(path: Routes.mfaSetup, builder: (_, __) => const MfaSetupScreen()),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: Routes.dashboard, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: Routes.portal, builder: (_, __) => const PortalScreen()),
          GoRoute(path: Routes.adminApprovals, builder: (_, __) => const ApprovalQueueScreen()),
          GoRoute(path: Routes.adminTenants, builder: (_, __) => const PlaceholderScreen(title: 'Tenants')),
          GoRoute(path: Routes.govRegistry, builder: (_, __) => const PlaceholderScreen(title: 'Gov Registry')),
          GoRoute(path: Routes.students, builder: (_, __) => const StudentDirectoryScreen()),
          GoRoute(path: '/school/students/:id', builder: (_, state) => StudentProfileScreen(studentId: state.pathParameters['id']!)),
          GoRoute(path: Routes.admissions, builder: (_, __) => const PlaceholderScreen(title: 'Admissions')),
          GoRoute(path: Routes.academics, builder: (_, __) => const AcademicSetupScreen()),
          GoRoute(path: Routes.assignments, builder: (_, __) => const PlaceholderScreen(title: 'Assignments')),
          GoRoute(path: Routes.timetable, builder: (_, __) => const PlaceholderScreen(title: 'Timetable')),
          GoRoute(path: Routes.homework, builder: (_, __) => const PlaceholderScreen(title: 'Homework')),
          GoRoute(path: Routes.exams, builder: (_, __) => const PlaceholderScreen(title: 'Exams & Marks')),
          GoRoute(path: Routes.attendance, builder: (_, __) => const PlaceholderScreen(title: 'Attendance Workspace')),
          GoRoute(path: Routes.finance, builder: (_, __) => const PlaceholderScreen(title: 'Fee Management')),
          GoRoute(path: Routes.feeCounter, builder: (_, __) => const PlaceholderScreen(title: 'Fee Counter')),
          GoRoute(path: Routes.reconciliation, builder: (_, __) => const PlaceholderScreen(title: 'Reconciliation')),
          GoRoute(path: Routes.grants, builder: (_, __) => const PlaceholderScreen(title: 'Government Grants')),
          GoRoute(path: Routes.budgets, builder: (_, __) => const PlaceholderScreen(title: 'Budgets')),
          GoRoute(path: Routes.expenses, builder: (_, __) => const PlaceholderScreen(title: 'Expenses')),
          GoRoute(path: Routes.hr, builder: (_, __) => const PlaceholderScreen(title: 'HR & Staff')),
          GoRoute(path: Routes.staffAttendance, builder: (_, __) => const PlaceholderScreen(title: 'Staff Attendance')),
          GoRoute(path: Routes.leave, builder: (_, __) => const PlaceholderScreen(title: 'Leave Requests')),
          GoRoute(path: Routes.payroll, builder: (_, __) => const PlaceholderScreen(title: 'Payroll')),
          GoRoute(path: Routes.library, builder: (_, __) => const PlaceholderScreen(title: 'Library')),
          GoRoute(path: Routes.transport, builder: (_, __) => const PlaceholderScreen(title: 'Transport')),
          GoRoute(path: Routes.inventory, builder: (_, __) => const PlaceholderScreen(title: 'Inventory')),
          GoRoute(path: Routes.notices, builder: (_, __) => const PlaceholderScreen(title: 'Notices Board')),
          GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: Routes.reports, builder: (_, __) => const PlaceholderScreen(title: 'Reports Center')),
          GoRoute(path: Routes.audit, builder: (_, __) => const PlaceholderScreen(title: 'Audit Log Viewer')),
          GoRoute(path: Routes.settings, builder: (_, __) => const PlaceholderScreen(title: 'Settings & Matrix')),
          GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class PlaceholderScreen extends StatefulWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  String _search = '';
  int _settingsSection = 0; // 0: Preferences, 1: Roles & Matrix, 2: Space & Users

  String _tableForTitle() {
    switch (widget.title.toLowerCase()) {
      case 'tenants':
        return 'tenants';
      case 'gov registry':
        return 'campuses';
      case 'admissions':
        return 'admissions';
      case 'assignments':
        return 'teacher_assignments';
      case 'timetable':
        return 'timetable_slots';
      case 'homework':
        return 'homework';
      case 'exams & marks':
        return 'exams';
      case 'attendance workspace':
        return 'attendance_sessions';
      case 'fee management':
      case 'fee counter':
      case 'reconciliation':
        return 'invoices';
      case 'government grants':
        return 'grants';
      case 'budgets':
        return 'budgets';
      case 'expenses':
        return 'expenses';
      case 'hr & staff':
      case 'staff attendance':
        return 'staff';
      case 'leave requests':
        return 'leave_requests';
      case 'payroll':
        return 'payroll_runs';
      case 'library':
        return 'library_items';
      case 'transport':
        return 'transport_routes';
      case 'inventory':
        return 'inventory_assets';
      case 'notices board':
        return 'notices';
      case 'audit log viewer':
        return 'audit_events';
      case 'settings & matrix':
        return 'roles';
      default:
        return 'profiles';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSettings = widget.title.toLowerCase() == 'settings & matrix';
    if (isSettings) {
      return _buildProfessionalSettings(context);
    }
    return _buildProModuleView(context);
  }

  Widget _buildProfessionalSettings(BuildContext context) {
    final client = Supabase.instance.client;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Settings & Access Matrix',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Configure workspace preferences, role matrix, and Supabase quota breakdown',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Chip(label: Text('Pro Workspace')),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('General & Preferences'),
              selected: _settingsSection == 0,
              onSelected: (_) => setState(() => _settingsSection = 0),
            ),
            ChoiceChip(
              label: const Text('Roles & Permissions'),
              selected: _settingsSection == 1,
              onSelected: (_) => setState(() => _settingsSection = 1),
            ),
            ChoiceChip(
              label: const Text('Space & User Data'),
              selected: _settingsSection == 2,
              onSelected: (_) => setState(() => _settingsSection = 2),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_settingsSection == 0) ...[
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.school_outlined, color: KsmsColors.teal600),
                  title: Text('Karachi School Management System (KSMS)'),
                  subtitle: Text('Multi-tenant & Multi-campus Academic + Finance + HR Suite'),
                  trailing: Chip(label: Text('Active')),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.translate, color: KsmsColors.teal600),
                  title: Text('Localization & RTL Support'),
                  subtitle: Text('Use top bar language toggle to switch between English and اردو'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.dark_mode_outlined, color: KsmsColors.teal600),
                  title: Text('Appearance & Contrast Mode'),
                  subtitle: Text('Use top bar theme icon to switch Light / Dark mode'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.speed_outlined, color: KsmsColors.teal600),
                  title: Text('Query Optimization & Paging'),
                  subtitle: Text('Bounded record fetching active for faster web & mobile rendering'),
                ),
              ],
            ),
          ),
        ] else if (_settingsSection == 1) ...[
          FutureBuilder(
            future: client.from('roles').select().limit(50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
              }
              final rows = snap.data != null ? List.of(snap.data as List) : [];
              if (rows.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No roles configured yet.')));
              }
              return Column(
                children: [
                  for (final item in rows)
                    Builder(builder: (context) {
                      final r = Map.of(item as Map);
                      final label = (r['label'] ?? r['name'] ?? r['role_key'] ?? r['key'] ?? 'Role').toString();
                      final scope = (r['scope'] ?? 'SYSTEM').toString();
                      final key = (r['key'] ?? r['role_key'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings_outlined)),
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(key.isEmpty ? 'Role policy active' : 'Role Key: $key'),
                          trailing: Chip(label: Text(scope)),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ] else ...[
          FutureBuilder(
            future: client.from('profiles').select().limit(50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
              }
              final users = snap.data != null ? List.of(snap.data as List) : [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Supabase Free Plan Reference: 500 MB Database • 1 GB Storage • 50k MAU. '
                        'Per-user exact disk bytes require Postgres admin stats; user accounts & records are listed below:',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (users.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No user profiles found.')))
                  else
                    for (var i = 0; i < users.length; i++)
                      Builder(builder: (context) {
                        final u = Map.of(users[i] as Map);
                        final name = (u['full_name'] ?? u['email'] ?? u['id'] ?? 'User #${i + 1}').toString();
                        final email = (u['email'] ?? u['role'] ?? 'Active member').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(email),
                            trailing: const Chip(label: Text('Est. ~0.03 MB')),
                          ),
                        );
                      }),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProModuleView(BuildContext context) {
    final client = Supabase.instance.client;
    final table = _tableForTitle();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text('Live Table: public.$table', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Chip(label: Text('Live DB')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filter records...',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder(
              future: client.from(table).select().limit(30),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading $table: ${snap.error}'),
                    ),
                  );
                }
                final raw = snap.data;
                final allRows = raw != null ? List.of(raw as List) : [];
                final rows = _search.isEmpty
                    ? allRows
                    : allRows.where((item) => item.toString().toLowerCase().contains(_search)).toList();

                if (rows.isEmpty) {
                  return Card(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(allRows.isEmpty
                            ? 'No records found in public.$table yet.'
                            : 'No matching records for "$_search".'),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final r = Map.of(rows[i] as Map);
                    final primary = (r['name'] ??
                            r['title'] ??
                            r['full_name'] ??
                            r['code'] ??
                            r['id'] ??
                            'Record #${i + 1}')
                        .toString();
                    final secondary = r.entries
                        .where((e) => e.key != 'id' && e.value != null)
                        .take(3)
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' • ');
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(primary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(secondary, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PortalScreen extends StatelessWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Parent / Student Portal'));
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: AsyncView<List<Map<String, dynamic>>>(
        value: list,
        isEmpty: (l) => l.isEmpty,
        builder: (context, rows) => ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final n = rows[i];
            final read = n['read_at'] != null;
            return ListTile(
              leading: Icon(read ? Icons.notifications_none : Icons.notifications_active,
                  color: read ? null : KsmsColors.teal500),
              title: Text(n['title'] ?? ''),
              subtitle: Text(n['body'] ?? ''),
              trailing: Text(F.date(DateTime.tryParse(n['created_at'] ?? ''))),
              onTap: () {
                if (!read) {
                  ref.read(notificationsProvider.notifier).markRead(n['id']);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
