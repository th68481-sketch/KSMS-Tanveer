import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/dashboard_providers.dart';
class SchoolDashboard extends ConsumerWidget {
  const SchoolDashboard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context); if (l == null) return const SizedBox.shrink();
    final scope = ref.watch(dashboardScopeProvider);
    final kpis = scope == null ? const AsyncValue.data({}) : ref.watch(schoolDashboardProvider(scope));
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionHeader(title: l.nav_dashboard),
      AsyncView(value: kpis, onRetry: () => ref.invalidate(schoolDashboardProvider), builder: (context, raw) {
        final k = raw is Map ? Map.of(raw as Map) : const {};
        final attT = (k['attendanceTotal'] is int) ? k['attendanceTotal'] as int : 0;
        final attP = (k['attendancePresent'] is int) ? k['attendancePresent'] as int : 0;
        final pct = attT > 0 ? (attP / attT * 100) : null;
        return GridView.count(crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.0, children: [
          InkWell(onTap: () => context.push(Routes.students), child: StatCard(label: l.dash_studentsActive, value: F.intFmt((k['students'] is int) ? k['students'] as int : 0), icon: Icons.groups, tone: KsmsColors.navy700)),
          InkWell(onTap: () => context.push(Routes.hr), child: StatCard(label: l.dash_staffActive, value: F.intFmt((k['staff'] is int) ? k['staff'] as int : 0), icon: Icons.badge, tone: KsmsColors.teal600)),
          InkWell(onTap: () => context.push(Routes.attendance), child: StatCard(label: l.dash_attendanceToday, value: pct == null ? '-' : '${pct.toStringAsFixed(1)}%', icon: Icons.fact_check, tone: KsmsColors.info, subtitle: '$attP / $attT')),
          InkWell(onTap: () => context.push(Routes.finance), child: StatCard(label: l.dash_feesDue, value: F.pkr((k['feesDue'] is num) ? (k['feesDue'] as num).toDouble() : 0.0), icon: Icons.request_quote, tone: KsmsColors.warning)),
          InkWell(onTap: () => context.push(Routes.leave), child: StatCard(label: l.dash_pendingLeaves, value: '${k['pendingLeaves'] ?? 0}', icon: Icons.beach_access, tone: KsmsColors.danger)),
          InkWell(onTap: () => context.push(Routes.homework), child: StatCard(label: l.dash_quickActions, value: '${k['homeworkDueToday'] ?? 0}', icon: Icons.menu_book, tone: KsmsColors.teal600, subtitle: l.hw_title)),
        ]);
      }),
    ]);
  }
}
class PlatformDashboard extends ConsumerWidget {
  const PlatformDashboard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context); if (l == null) return const SizedBox.shrink();
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionHeader(title: l.nav_dashboard),
      AsyncView(value: ref.watch(platformDashboardProvider), onRetry: () => ref.invalidate(platformDashboardProvider), builder: (context, raw) {
        final k = raw is Map ? Map.of(raw as Map) : const {};
        return GridView.count(crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 5 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.0, children: [
          InkWell(onTap: () => context.go(Routes.adminTenants), child: StatCard(label: l.dash_privateSchools, value: '${k['private'] ?? 0}', icon: Icons.domain)),
          InkWell(onTap: () => context.go(Routes.adminTenants), child: StatCard(label: l.dash_govSchools, value: '${k['government'] ?? 0}', icon: Icons.account_balance)),
          InkWell(onTap: () => context.go(Routes.govRegistry), child: StatCard(label: l.dash_campuses, value: '${k['campuses'] ?? 0}', icon: Icons.location_city)),
          InkWell(onTap: () => context.go(Routes.adminApprovals), child: StatCard(label: l.dash_pendingRequests, value: '${k['pendingRequests'] ?? 0}', icon: Icons.approval, tone: KsmsColors.warning)),
          InkWell(onTap: () => context.go(Routes.adminTenants), child: StatCard(label: l.dash_suspended, value: '${k['suspended'] ?? 0}', icon: Icons.pause_circle, tone: KsmsColors.danger)),
        ]);
      }),
    ]);
  }
}
class GovDashboard extends ConsumerWidget {
  const GovDashboard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context); if (l == null) return const SizedBox.shrink();
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionHeader(title: l.dash_schoolsInJurisdiction),
      AsyncView(value: ref.watch(govDashboardProvider), onRetry: () => ref.invalidate(govDashboardProvider), builder: (context, raw) {
        final k = raw is Map ? Map.of(raw as Map) : const {};
        return GridView.count(crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 3 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.0, children: [
          InkWell(onTap: () => context.go(Routes.govRegistry), child: StatCard(label: l.nav_registry, value: '${k['schools'] ?? 0}', icon: Icons.account_balance)),
          InkWell(onTap: () => context.go(Routes.students), child: StatCard(label: l.dash_studentsActive, value: '${k['students'] ?? 0}', icon: Icons.groups)),
          InkWell(onTap: () => context.go(Routes.adminApprovals), child: StatCard(label: l.dash_pendingRequests, value: '${k['pendingRequests'] ?? 0}', icon: Icons.approval, tone: KsmsColors.warning)),
        ]);
      }),
    ]);
  }
}
