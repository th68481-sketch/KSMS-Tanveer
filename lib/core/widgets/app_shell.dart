import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ksms/core/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/session_controller.dart';
import '../../features/communications/providers/notifications_providers.dart';
import '../providers/app_settings.dart';
import '../router/route_paths.dart';
import '../theme/design_tokens.dart';
import '../utils/formatters.dart';
import 'nav_registry.dart';
import 'sync_status_banner.dart';
import '../../l10n/generated/app_localizations.dart';

/// Responsive application frame:
///  - Wide: collapsible sidebar
///  - Medium: icon rail
///  - Compact: drawer
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _expanded = true;

  SessionState get _session =>
      ref.watch(sessionProvider).valueOrNull ?? const SessionState(phase: SessionPhase.loading);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final unread = ref.watch(unreadCountProvider);

    final sidebar = _buildNavList(context, expanded: _expanded);

    return Scaffold(
      body: Row(
        children: [
          if (_showSidebar) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _expanded ? 248 : 64,
              color: Theme.of(context).brightness == Brightness.light
                  ? KsmsColors.navy800
                  : KsmsColors.navy900,
              child: sidebar,
            ),
          ],
          Expanded(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: _buildTopBar(context, l, settings, unread),
              drawer: _showSidebar ? null : _buildDrawer(context),
              body: Column(
                children: [
                  if (_session.error != null)
                    Material(
                      color: KsmsColors.danger.withOpacity(0.08),
                      child: InkWell(
                        onTap: () => ref.read(sessionProvider.notifier).refreshContext(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(children: [
                            const Icon(Icons.cloud_off, size: 16, color: KsmsColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${l.common_offlineHint} (${_session.error})',
                                  style: Theme.of(context).textTheme.labelSmall),
                            ),
                            TextButton(onPressed: () => ref.read(sessionProvider.notifier).refreshContext(), child: Text(l.common_retry)),
                          ]),
                        ),
                      ),
                    ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _showSidebar => MediaQuery.of(context).size.width >= 1000;

  AppBar _buildTopBar(BuildContext context, AppLocalizations l, AppSettings settings, int unread) {
    final session = _session;
    final profileName = (session.profile['full_name'] as String?) ?? '';
    final role = session.primaryRole;

    return AppBar(
      titleSpacing: 12,
      title: Row(
        children: [
          if (session.isSchoolUser && session.tenants.length > 1)
            _tenantSwitcher(context, session),
          if (session.isSchoolUser && session.activeCampuses.length > 1)
            const SizedBox(width: 8),
          if (session.isSchoolUser && session.activeCampuses.length > 1)
            _campusSwitcher(context, session),
          const Spacer(),
          const SyncStatusBanner(compact: true),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l.nav_notifications,
            onPressed: () => context.push(Routes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate),
            onSelected: (v) => ref.read(appSettingsProvider.notifier).setLocale(v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ur', child: Text('اردو')),
            ],
          ),
          IconButton(
            tooltip: 'Theme',
            onPressed: () => ref.read(appSettingsProvider.notifier).setThemeMode(
                  settings.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                ),
            icon: Icon(settings.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: profileName.isEmpty ? 'Profile' : profileName,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: KsmsColors.teal500.withOpacity(0.2),
            child: Text(
              profileName.isNotEmpty ? profileName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 14, color: KsmsColors.teal600),
            ),
          ),
          onSelected: (v) async {
            switch (v) {
              case 'profile':
                context.push(Routes.profile);
              case 'signout':
                final ok = await confirmAction(
                  context,
                  title: 'Sign out',
                  message: 'Are you sure you want to sign out of KSMS?',
                  confirmLabel: 'Sign out',
                  destructive: true,
                );
                if (ok) {
                  await ref.read(sessionProvider.notifier).signOut();
                  if (context.mounted) context.go(Routes.signIn);
                }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profileName, style: Theme.of(context).textTheme.titleSmall),
                  if (role != null)
                    Text(F.humanize(role.key), style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'signout', child: Text('Sign out')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _tenantSwitcher(BuildContext context, SessionState session) {
    return PopupMenuButton<String>(
      tooltip: 'Organization',
      onSelected: (v) => ref.read(sessionProvider.notifier).switchTenant(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: KsmsColors.navy100.withOpacity(0.4),
          borderRadius: KsmsRadii.sm,
        ),
        child: Row(children: [
          const Icon(Icons.domain, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(session.activeTenant?.name ?? '—',
                overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
          ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ]),
      ),
      itemBuilder: (_) => [
        for (final t in session.tenants)
          PopupMenuItem(
            value: t.id,
            child: Text('${t.name} (${t.status.toLowerCase()})'),
          ),
      ],
    );
  }

  Widget _campusSwitcher(BuildContext context, SessionState session) {
    return PopupMenuButton<String>(
      tooltip: 'Campus',
      onSelected: (v) => ref.read(sessionProvider.notifier).switchCampus(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: KsmsColors.teal100, borderRadius: KsmsRadii.sm),
        child: Row(children: [
          const Icon(Icons.location_city, size: 16),
          const SizedBox(width: 6),
          Text(session.campuses.where((c) => c.id == session.activeCampusId).firstOrNull?.name ?? 'All',
              style: Theme.of(context).textTheme.labelLarge),
          const Icon(Icons.arrow_drop_down, size: 18),
        ]),
      ),
      itemBuilder: (_) => [
        for (final c in session.activeCampuses)
          PopupMenuItem(value: c.id, child: Text('${c.name} · ${c.code}')),
      ],
    );
  }

  Widget _buildNavList(BuildContext context, {required bool expanded}) {
    final l = AppLocalizations.of(context)!;
    final router = GoRouterState.of(context).matchedLocation;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: KsmsColors.teal500, borderRadius: KsmsRadii.sm),
                alignment: Alignment.center,
                child: const Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              if (expanded) ...[
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('KSMS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final section in navSections)
                ...[
                  if (section.items.any((i) => i.applies(_session))) ...[
                    if (expanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                        child: Text(section.title(l).toUpperCase(),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.45),
                                letterSpacing: 0.6)),
                      ),
                    for (final item in section.items.where((i) => i.applies(_session)))
                      _NavTile(
                        item: item,
                        label: item.label(l),
                        selected: router == item.path,
                        expanded: expanded,
                        onTap: () {
                          final rootScaffold = context.findRootAncestorStateOfType<ScaffoldState>();
                          if (rootScaffold?.isDrawerOpen ?? false) {
                            Navigator.of(context).pop();
                          }
                          context.go(item.path);
                        },
                      ),
                  ],
                ],
            ],
          ),
        ),
        _DrawerSupabaseQuotaMeter(expanded: expanded),
        if (_showSidebar)
          IconButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(expanded ? Icons.chevron_left : Icons.chevron_right, color: Colors.white70),
          ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _buildNavList(context, expanded: true),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final NavItemSpec item;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? KsmsColors.teal400 : Colors.white.withOpacity(0.78);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        borderRadius: KsmsRadii.sm,
        child: InkWell(
          borderRadius: KsmsRadii.sm,
          onTap: onTap,
          child: Tooltip(
            message: expanded ? '' : label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Icon(item.icon, size: 19, color: color),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _DrawerSupabaseQuotaMeter extends StatefulWidget {
  const _DrawerSupabaseQuotaMeter({required this.expanded});
  final bool expanded;

  @override
  State<_DrawerSupabaseQuotaMeter> createState() => _DrawerSupabaseQuotaMeterState();
}

class _DrawerSupabaseQuotaMeterState extends State<_DrawerSupabaseQuotaMeter> {
  late final _usageFuture = _loadUsage();

  Future _loadUsage() async {
    final client = Supabase.instance.client;
    int totalRows = 0;
    int storageBytes = 0;
    int userCount = 0;

    final tables = [
      'profiles',
      'tenants',
      'campuses',
      'students',
      'admissions',
      'invoices',
      'attendance_sessions',
      'staff',
      'notices',
      'audit_events',
    ];

    for (final t in tables) {
      try {
        final rows = await client.from(t).select('id').limit(200);
        if (rows is List) {
          totalRows += rows.length;
          if (t == 'profiles') userCount = rows.length;
        }
      } catch (_) {}
    }

    try {
      final buckets = await client.storage.listBuckets();
      for (final b in buckets) {
        try {
          final files = await client.storage.from(b.name).list();
          for (final item in files) {
            final meta = item.metadata;
            if (meta != null && meta['size'] != null) {
              storageBytes += int.tryParse(meta['size'].toString()) ?? 0;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    const freeDbCapMb = 500.0;
    const freeStorageCapMb = 1024.0;
    final estimatedDbMb = (totalRows * 0.025).clamp(0.2, freeDbCapMb);
    final storageMb = storageBytes / (1024 * 1024);
    final dbRatio = (estimatedDbMb / freeDbCapMb).clamp(0.01, 1.0);
    final storageRatio = (storageMb / freeStorageCapMb).clamp(0.005, 1.0);
    final balanceDbMb = (freeDbCapMb - estimatedDbMb).clamp(0.0, freeDbCapMb);

    return {
      'totalRows': totalRows,
      'userCount': userCount,
      'estimatedDbMb': estimatedDbMb,
      'balanceDbMb': balanceDbMb,
      'dbRatio': dbRatio,
      'storageMb': storageMb,
      'storageRatio': storageRatio,
    };
  }

@override
  Widget build(BuildContext context) {
    if (!widget.expanded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Tooltip(
          message: 'Supabase Free Quota (500 MB DB / 1 GB Storage)',
          child: Icon(Icons.cloud_done_outlined, size: 18, color: KsmsColors.teal400),
        ),
      );
    }

    return FutureBuilder(
      future: _usageFuture,
      builder: (context, snap) {
        final d = snap.data is Map ? Map.from(snap.data as Map) : const {};
        final double dbRatio = (d['dbRatio'] is num) ? (d['dbRatio'] as num).toDouble() : 0.04;
        final double usedDb = (d['estimatedDbMb'] is num) ? (d['estimatedDbMb'] as num).toDouble() : 0.5;
        final double balDb = (d['balanceDbMb'] is num) ? (d['balanceDbMb'] as num).toDouble() : 499.5;
        final double usedStorage = (d['storageMb'] is num) ? (d['storageMb'] as num).toDouble() : 0.0;
        final int rowsCount = (d['totalRows'] is int) ? d['totalRows'] as int : 0;
        final int usersCount = (d['userCount'] is int) ? d['userCount'] as int : 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: KsmsRadii.sm,
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storage_rounded, size: 14, color: KsmsColors.teal400),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Supabase Free Space',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '500 MB',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10.5),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: dbRatio,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.14),
                  valueColor: const AlwaysStoppedAnimation<Color>(KsmsColors.teal400),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Used ~${usedDb.toStringAsFixed(1)} MB',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                  ),
                  Text(
                    'Bal ~${balDb.toStringAsFixed(0)} MB',
                    style: const TextStyle(color: KsmsColors.teal400, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Storage: ${usedStorage.toStringAsFixed(2)} MB / 1 GB • Recs: $rowsCount • Users: $usersCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 9.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
