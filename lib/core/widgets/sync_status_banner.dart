import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/sync_engine.dart';
import '../theme/design_tokens.dart';

/// Persistent indicator of the encrypted offline queue state.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncEngineProvider);
    final theme = Theme.of(context);

    if (sync.phase == SyncPhase.idle && sync.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final (icon, color, label) = switch (sync.phase) {
      SyncPhase.syncing => (Icons.sync, KsmsColors.info, 'Syncing ${sync.pendingCount}…'),
      SyncPhase.offline => (Icons.cloud_off, KsmsColors.warning,
          'Offline — ${sync.pendingCount} queued (encrypted)'),
      SyncPhase.error when sync.hasConflicts =>
        (Icons.warning_amber, KsmsColors.danger, 'Conflicts need review'),
      SyncPhase.error => (Icons.error_outline, KsmsColors.danger,
          'Sync error — will retry (${sync.pendingCount} queued)'),
      _ => (Icons.sync, KsmsColors.info, '${sync.pendingCount} queued'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: KsmsRadii.sm,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: sync.hasConflicts ? null : () => ref.read(syncEngineProvider.notifier).flush(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
            if (sync.phase == SyncPhase.error && !sync.hasConflicts) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => ref.read(syncEngineProvider.notifier).flush(),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('Retry', style: TextStyle(decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
