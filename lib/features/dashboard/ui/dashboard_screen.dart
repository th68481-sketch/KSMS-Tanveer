import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/session_controller.dart';
import 'dashboards.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();

    if (session.isPlatformAdmin) return const PlatformDashboard();
    if (session.isGovAdmin) return const GovDashboard();
    return const SchoolDashboard();
  }
}
