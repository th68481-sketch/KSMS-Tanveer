import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../features/auth/providers/session_controller.dart';
import '../constants/domain.dart' hide SessionState;
import '../router/route_paths.dart';

class NavItemSpec {
  const NavItemSpec({
    required this.path,
    required this.icon,
    required this.label,
    this.permission,
    this.visible,
  });

  final String path;
  final IconData icon;
  final String Function(AppLocalizations l) label;
  final String? permission;
  final bool Function(SessionState session)? visible;

  bool applies(SessionState session) {
    if (visible != null && !visible!(session)) return false;
    if (permission != null && !session.can(permission!)) return false;
    return true;
  }
}

class NavSection {
  const NavSection({required this.title, required this.items});
  final String Function(AppLocalizations l) title;
  final List<NavItemSpec> items;
}

bool _school(SessionState s) => s.isSchoolUser;
bool _platform(SessionState s) => s.isPlatformAdmin;
bool _gov(SessionState s) => s.isGovAdmin;
bool _parentOrStudent(SessionState s) =>
    s.memberships.any((m) => m.roleKey == UserRole.parent.key || m.roleKey == UserRole.student.key);

final navSections = <NavSection>[
  NavSection(title: (l) => l.sec_overview, items: [
    NavItemSpec(path: Routes.dashboard, icon: Icons.dashboard_outlined, label: (l) => l.nav_dashboard),
    NavItemSpec(
      path: Routes.portal,
      icon: Icons.family_restroom,
      label: (l) => l.nav_portal,
      visible: _parentOrStudent,
    ),
  ]),
  NavSection(title: (l) => l.sec_access, items: [
    NavItemSpec(
      path: Routes.adminApprovals,
      icon: Icons.approval_outlined,
      label: (l) => l.nav_approvals,
      visible: (s) => _platform(s) || _gov(s),
    ),
    NavItemSpec(
      path: Routes.adminTenants,
      icon: Icons.domain_outlined,
      label: (l) => l.nav_tenants,
      visible: _platform,
    ),
    NavItemSpec(
      path: Routes.govRegistry,
      icon: Icons.public,
      label: (l) => l.nav_registry,
      visible: (s) => _gov(s) && s.can(Permissions.govRegistryRead),
    ),
  ]),
  NavSection(title: (l) => l.sec_students, items: [
    NavItemSpec(
      path: Routes.students,
      icon: Icons.groups_outlined,
      label: (l) => l.nav_students,
      visible: (s) => _school(s) && s.can(Permissions.studentsRead),
    ),
    NavItemSpec(
      path: Routes.admissions,
      icon: Icons.assignment_outlined,
      label: (l) => l.nav_admissions,
      visible: (s) => _school(s) && s.can(Permissions.admissionsWrite),
    ),
  ]),
  NavSection(title: (l) => l.sec_academics, items: [
    NavItemSpec(
      path: Routes.academics,
      icon: Icons.school_outlined,
      label: (l) => l.nav_academics,
      visible: (s) => _school(s) && s.can(Permissions.academicsManage),
    ),
    NavItemSpec(
      path: Routes.assignments,
      icon: Icons.fact_check_outlined,
      label: (l) => l.nav_assignments,
      visible: (s) => _school(s) && s.can(Permissions.assignmentsManage),
    ),
    NavItemSpec(
      path: Routes.timetable,
      icon: Icons.calendar_month_outlined,
      label: (l) => l.nav_timetable,
      visible: (s) => _school(s) && s.can(Permissions.timetableManage),
    ),
    NavItemSpec(
      path: Routes.homework,
      icon: Icons.menu_book_outlined,
      label: (l) => l.nav_homework,
      visible: (s) => _school(s) && (s.can(Permissions.homeworkWrite) || s.can(Permissions.homeworkRead)),
    ),
    NavItemSpec(
      path: Routes.exams,
      icon: Icons.quiz_outlined,
      label: (l) => l.nav_exams,
      visible: (s) => _school(s) && (s.can(Permissions.examsManage) || s.can(Permissions.marksEnter)),
    ),
    NavItemSpec(
      path: Routes.attendance,
      icon: Icons.fact_check,
      label: (l) => l.nav_attendance,
      visible: (s) => _school(s) && (s.can(Permissions.attendanceMark) || s.can(Permissions.attendanceRead)),
    ),
  ]),
  NavSection(title: (l) => l.sec_finance, items: [
    NavItemSpec(
      path: Routes.finance,
      icon: Icons.request_quote_outlined,
      label: (l) => l.nav_feeManagement,
      visible: (s) => _school(s) && s.can(Permissions.financePrivateView),
    ),
    NavItemSpec(
      path: Routes.feeCounter,
      icon: Icons.payments_outlined,
      label: (l) => l.nav_feeCounter,
      visible: (s) => _school(s) && s.can(Permissions.financeCollect),
    ),
    NavItemSpec(
      path: Routes.reconciliation,
      icon: Icons.receipt_long_outlined,
      label: (l) => l.nav_reconciliation,
      visible: (s) => _school(s) && s.can(Permissions.financePrivateView),
    ),
    NavItemSpec(
      path: Routes.grants,
      icon: Icons.account_balance_wallet_outlined,
      label: (l) => l.nav_grants,
      visible: (s) => _school(s) && s.can(Permissions.financeGovView),
    ),
    NavItemSpec(
      path: Routes.budgets,
      icon: Icons.savings_outlined,
      label: (l) => l.nav_budgets,
      visible: (s) => _school(s) && s.can(Permissions.financeGovView),
    ),
    NavItemSpec(
      path: Routes.expenses,
      icon: Icons.receipt,
      label: (l) => l.nav_expenses,
      visible: (s) => _school(s) && s.can(Permissions.financeGovView),
    ),
  ]),
  NavSection(title: (l) => l.sec_people, items: [
    NavItemSpec(
      path: Routes.hr,
      icon: Icons.badge_outlined,
      label: (l) => l.nav_hr,
      visible: (s) => _school(s) && s.can(Permissions.hrManage),
    ),
    NavItemSpec(
      path: Routes.staffAttendance,
      icon: Icons.timelapse,
      label: (l) => l.nav_staffAttendance,
      visible: (s) => _school(s) && s.can(Permissions.hrManage),
    ),
    NavItemSpec(
      path: Routes.leave,
      icon: Icons.beach_access,
      label: (l) => l.nav_leave,
      visible: (s) => _school(s) && (s.can(Permissions.hrManage) || s.can(Permissions.leaveApprove)),
    ),
    NavItemSpec(
      path: Routes.payroll,
      icon: Icons.account_balance,
      label: (l) => l.nav_payroll,
      visible: (s) => _school(s) && s.can(Permissions.payrollManage),
    ),
    NavItemSpec(
      path: Routes.library,
      icon: Icons.local_library_outlined,
      label: (l) => l.nav_library,
      visible: (s) => _school(s) && s.can(Permissions.libraryManage),
    ),
    NavItemSpec(
      path: Routes.transport,
      icon: Icons.directions_bus_outlined,
      label: (l) => l.nav_transport,
      visible: (s) => _school(s) && s.can(Permissions.transportManage),
    ),
    NavItemSpec(
      path: Routes.inventory,
      icon: Icons.inventory_2_outlined,
      label: (l) => l.nav_inventory,
      visible: (s) => _school(s) && s.can(Permissions.inventoryManage),
    ),
  ]),
  NavSection(title: (l) => l.sec_system, items: [
    NavItemSpec(
      path: Routes.notices,
      icon: Icons.campaign_outlined,
      label: (l) => l.nav_notices,
      visible: (s) => _school(s) && (s.can(Permissions.noticesCompose) || s.can(Permissions.notificationsRead)),
    ),
    NavItemSpec(
      path: Routes.reports,
      icon: Icons.assessment_outlined,
      label: (l) => l.nav_reports,
      visible: (s) => (s.can(Permissions.reportsExport) || _platform(s) || _gov(s)) && !_parentOrStudent(s),
    ),
    NavItemSpec(
      path: Routes.audit,
      icon: Icons.receipt_long,
      label: (l) => l.nav_audit,
      visible: (s) => s.can(Permissions.auditRead),
    ),
    NavItemSpec(
      path: Routes.settings,
      icon: Icons.settings_outlined,
      label: (l) => l.nav_settings,
      visible: (s) => !_parentOrStudent(s),
    ),
  ]),
];
