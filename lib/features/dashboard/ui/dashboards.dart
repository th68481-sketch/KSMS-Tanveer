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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scope = ref.watch(dashboardScopeProvider);
    final kpis = scope == null
        ? const AsyncValue<Map<String, dynamic>>.data({})
        : ref.watch(schoolDashboardProvider(scope));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: l.nav_dashboard),
        AsyncView<Map<String, dynamic>>(
          value: kpis,
          onRetry: () => ref.invalidate(schoolDashboardProvider),
          builder: (context, k) {
            final attPct = (k['attendanceTotal'] as int) > 0
                ? ((k['attendancePresent'] as int) / (k['attendanceTotal'] as int) * 100)
                : null;
            return LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 720
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  StatCard(label: l.dash_studentsActive, value: F.intFmt(k['students'] as int), icon: Icons.groups, tone: KsmsColors.navy700),
                  StatCard(label: l.dash_staffActive, value: F.intFmt(k['staff'] as int), icon: Icons.badge, tone: KsmsColors.teal600),
                  StatCard(
                    label: l.dash_attendanceToday,
                    value: attPct == null ? '—' : '${attPct.toStringAsFixed(1)}%',
                    icon: Icons.fact_check,
                    tone: KsmsColors.info,
                    subtitle: '${k['attendancePresent']} / ${k['attendanceTotal']}',
                  ),
                  StatCard(label: l.dash_feesDue, value: F.pkr(k['feesDue'] as double), icon: Icons.request_quote, tone: KsmsColors.warning),
                  StatCard(label: l.dash_pendingLeaves, value: '${k['pendingLeaves']}', icon: Icons.beach_access, tone: KsmsColors.danger),
                  StatCard(label: l.dash_quickActions, value: '${k['homeworkDueToday']}', icon: Icons.menu_book, tone: KsmsColors.teal600, subtitle: l.hw_title),
                ],
              );
            });
          },
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.attendance),
              icon: const Icon(Icons.fact_check),
              label: Text(l.att_mark),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.feeCounter),
              icon: const Icon(Icons.payments),
              label: Text(l.nav_feeCounter),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.admissions),
              icon: const Icon(Icons.assignment),
              label: Text(l.nav_admissions),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.notices),
              icon: const Icon(Icons.campaign),
              label: Text(l.notices_new),
            ),
          ],
        ),
      ],
    );
  }
}

class PlatformDashboard extends ConsumerWidget {
  const PlatformDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final data = ref.watch(platformDashboardProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: l.nav_dashboard),
        AsyncView<Map<String, dynamic>>(
          value: data,
          onRetry: () => ref.invalidate(platformDashboardProvider),
          builder: (context, k) => Column(
            children: [
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 1000 ? 5 : 2;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: [
                    StatCard(label: l.dash_privateSchools, value: '${k['private']}', icon: Icons.domain),
                    StatCard(label: l.dash_govSchools, value: '${k['government']}', icon: Icons.account_balance),
                    StatCard(label: l.dash_campuses, value: '${k['campuses']}', icon: Icons.location_city),
                    StatCard(label: l.dash_pendingRequests, value: '${k['pendingRequests']}', icon: Icons.approval, tone: KsmsColors.warning),
                    StatCard(label: l.dash_suspended, value: '${k['suspended']}', icon: Icons.pause_circle, tone: KsmsColors.danger),
                  ],
                );
              }),
              const SizedBox(height: 24),
              SectionHeader(title: l.dash_recentAudit),
              Card(
                child: Column(
                  children: [
                    for (final e in (k['recentAudit'] as List).cast<Map<String, dynamic>>())
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 18),
                        title: Text('${e['action']} · ${e['entity']}'),
                        subtitle: Text(F.dateTime(F.tryParseDate(e['created_at'] as String?))),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GovDashboard extends ConsumerWidget {
  const GovDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final data = ref.watch(govDashboardProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: l.dash_schoolsInJurisdiction),
        AsyncView<Map<String, dynamic>>(
          value: data,
          onRetry: () => ref.invalidate(govDashboardProvider),
          builder: (context, k) => Column(
            children: [
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 1000 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: [
                    StatCard(label: l.nav_registry, value: '${k['schools']}', icon: Icons.account_balance),
                    StatCard(label: l.dash_studentsActive, value: '${k['students']}', icon: Icons.groups),
                    StatCard(label: l.dash_pendingRequests, value: '${k['pendingRequests']}', icon: Icons.approval, tone: KsmsColors.warning),
                  ],
                );
              }),
              const SizedBox(height: 16),
              SectionHeader(title: l.nav_registry),
              Card(
                child: Column(
                  children: [
                    for (final t in (k['schoolsList'] as List).cast<Map<String, dynamic>>())
                      ListTile(
                        title: Text((t['name'] as String?) ?? ''),
                        subtitle: Text('${t['gov_district'] ?? ''} · SEMIS ${t['semis_code'] ?? '—'}'),
                        trailing: StatusChip(status: (t['status'] as String?) ?? '', dense: true),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
