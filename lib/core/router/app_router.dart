import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/domain.dart';
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
            return Routes.dashboard;
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

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 48, color: Colors.amber),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Fully specified in DB schema & backend RPCs. UI module module expansion ready.'),
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
