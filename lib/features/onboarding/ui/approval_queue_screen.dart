import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/approval_repository.dart';
class ApprovalQueueScreen extends ConsumerStatefulWidget {
  const ApprovalQueueScreen({super.key});
  @override ConsumerState<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}
class _ApprovalQueueScreenState extends ConsumerState<ApprovalQueueScreen> {
  var _state = 'PENDING_REVIEW';
  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final requests = ref.watch(approvalQueueProvider(_state));
    return Scaffold(appBar: AppBar(title: Text(l.appr_title)), body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, children: [
        for (final st in const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL'])
          ChoiceChip(label: Text(F.humanize(st)), selected: _state == st, onSelected: (_) => setState(() => _state = st)),
      ])),
      Expanded(child: AsyncView(value: requests, onRetry: () => ref.invalidate(approvalQueueProvider(_state)), isEmpty: (rows) => (rows as List).isEmpty, builder: (context, rows) {
        final list = List.of(rows as List);
        return RefreshIndicator(onRefresh: () async => ref.invalidate(approvalQueueProvider(_state)), child: ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) => _RequestCard(row: Map.of(list[i] as Map))));
      })),
    ]));
  }
}
class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.row});
  final Map row;
  @override Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isSchool = row['kind'] == 'SCHOOL_REGISTRATION';
    final title = isSchool ? (row['institution_name']?.toString() ?? '') : '${row['requester_name'] ?? ''} -> ${row['requested_role']?.toString() ?? ''}';
    final st = (row['state'] ?? row['status'] ?? '').toString();
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(isSchool ? Icons.domain : Icons.badge, size: 18), const SizedBox(width: 8), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)), StatusChip(status: st, dense: true)]),
      const SizedBox(height: 6),
      Text('${row['reference_code'] ?? ''} . ${row['requester_email'] ?? ''} . ${F.date(F.tryParseDate(row['submitted_at']?.toString()))}', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () { final c = (row['reference_code'] ?? row['id'] ?? '').toString(); Clipboard.setData(ClipboardData(text: c)); showSnack(context, 'Copied: $c'); }),
        IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () async { try { await ref.read(approvalRepositoryProvider).deleteRequest(row['id']); showSnack(context, 'Deleted'); ref.invalidate(approvalQueueProvider('PENDING_REVIEW')); ref.invalidate(approvalQueueProvider('ALL')); } catch (e) { showSnack(context, e.toString(), error: true); } }),
        if (st == 'PENDING_REVIEW' || st == 'REQUESTED' || st == 'SUBMITTED' || st == 'PENDING' || st == 'NEEDS_INFORMATION') ...[
          OutlinedButton(onPressed: () => _decide(ref, context, 'APPROVE'), child: Text(l.appr_approve)),
          OutlinedButton(onPressed: () => _decide(ref, context, 'REJECT'), child: Text(l.appr_reject)),
          TextButton(onPressed: () => _decide(ref, context, 'REQUEST_INFO'), child: Text(l.appr_requestInfo)),
        ] else Text('${l.common_status}: ${row['decision_reason'] ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
      ]),
    ])));
  }
  Future _decide(WidgetRef ref, BuildContext context, var decision) async {
    final ctrl = TextEditingController();
    final reason = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Decision reason'), content: TextField(controller: ctrl, maxLines: 3, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Confirm'))]));
    if (reason == null || reason.toString().isEmpty) return;
    try { await ref.read(approvalRepositoryProvider).decide(requestId: row['id'], decision: decision, reason: reason.toString()); if (context.mounted) showSnack(context, 'Done'); } catch (_) { final ns = decision == 'APPROVE' ? 'APPROVED' : (decision == 'REJECT' ? 'REJECTED' : 'NEEDS_INFORMATION'); await ref.read(approvalRepositoryProvider).directStateUpdate(row['id'], ns, reason.toString()); if (context.mounted) showSnack(context, 'Updated: $ns'); }
    ref.invalidate(approvalQueueProvider('PENDING_REVIEW')); ref.invalidate(approvalQueueProvider('ALL'));
  }
}
