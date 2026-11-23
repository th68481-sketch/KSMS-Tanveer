import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/approval_repository.dart';

class ApprovalQueueScreen extends ConsumerStatefulWidget {
  const ApprovalQueueScreen({super.key});

  @override
  ConsumerState<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends ConsumerState<ApprovalQueueScreen> {
  String _state = 'PENDING_REVIEW';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final requests = ref.watch(approvalQueueProvider(_state));

    return Scaffold(
      appBar: AppBar(title: Text(l.appr_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL'])
                  ChoiceChip(
                    label: Text(F.humanize(s)),
                    selected: _state == s,
                    onSelected: (_) => setState(() => _state = s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<Map<String, dynamic>>>(
              value: requests,
              onRetry: () => ref.invalidate(approvalQueueProvider(_state)),
              isEmpty: (rows) => rows.isEmpty,
              builder: (context, rows) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(approvalQueueProvider(_state)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _RequestCard(row: rows[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isSchool = row['kind'] == 'SCHOOL_REGISTRATION';
    final title = isSchool
        ? (row['institution_name'] as String?) ?? ''
        : '${row['requester_name']} → ${(row['requested_role'] as String?) ?? ''}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isSchool ? Icons.domain : Icons.badge, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                ),
                StatusChip(status: (row['state'] as String?) ?? '', dense: true),
              ],
            ),
            const SizedBox(height: 6),
            Text('${row['reference_code']} · ${row['requester_email']} · ${F.date(F.tryParseDate(row['submitted_at'] as String?))}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy Reference',
                  onPressed: () {
                    final refCode = (row['reference_code'] ?? row['id'] ?? '').toString();
                    Clipboard.setData(ClipboardData(text: refCode));
                    showSnack(context, 'Copied: $refCode');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete Request',
                  onPressed: () async {
                    try {
                      await ref.read(approvalRepositoryProvider).deleteRequest(row['id'].toString());
                      showSnack(context, 'Request deleted');
                      ref.invalidate(approvalQueueProvider('PENDING_REVIEW'));
                      ref.invalidate(approvalQueueProvider('ALL'));
                    } catch (e) {
                      showSnack(context, e.toString(), error: true);
                    }
                  },
                ),
                if ((row['state'] as String?) == 'PENDING_REVIEW' ||
                    (row['state'] as String?) == 'NEEDS_INFORMATION') ...[
                  OutlinedButton(
                    onPressed: () => _decide(ref, context, 'APPROVE'),
                    child: Text(l.appr_approve),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _decide(ref, context, 'REJECT'),
                    child: Text(l.appr_reject),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _decide(ref, context, 'REQUEST_INFO'),
                    child: Text(l.appr_requestInfo),
                  ),
                ] else
                  Text('${l.common_status}: ${row['decision_reason'] ?? '—'}',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _decide(WidgetRef ref, BuildContext context, String decision) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decision reason'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Mandatory justification…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) {
      if (context.mounted) {
        showSnack(context, AppLocalizations.of(context)!.appr_reasonRequired, error: true);
      }
      return;
    }
    try {
      final res = await ref.read(approvalRepositoryProvider).decide(
            requestId: row['id'] as String,
            decision: decision,
            reason: reason,
          );
      if (context.mounted) {
        final msg = res?['message'] as String?;
        showSnack(context, msg ?? (decision == 'APPROVE' ? AppLocalizations.of(context)!.appr_provisioned : 'Done'));
      }
      ref.invalidate(approvalQueueProvider('PENDING_REVIEW'));
      ref.invalidate(approvalQueueProvider('ALL'));
    } catch (e) {
      final mappedState = decision == 'APPROVE'
          ? 'APPROVED'
          : decision == 'REJECT'
              ? 'REJECTED'
              : 'NEEDS_INFORMATION';
      try {
        await ref.read(approvalRepositoryProvider).directStateUpdate(
              row['id'].toString(),
              mappedState,
              reason,
            );
        if (context.mounted) {
          showSnack(context, 'Updated status to $mappedState');
        }
        ref.invalidate(approvalQueueProvider('PENDING_REVIEW'));
        ref.invalidate(approvalQueueProvider('ALL'));
      } catch (e2) {
        if (context.mounted) showSnack(context, e2.toString(), error: true);
      }
    }
  }
}
