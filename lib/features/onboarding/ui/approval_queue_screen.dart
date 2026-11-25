import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/approval_repository.dart';

class ApprovalQueueScreen extends ConsumerStatefulWidget {
  const ApprovalQueueScreen({super.key});
  @override
  ConsumerState<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends ConsumerState<ApprovalQueueScreen> {
  var _state = 'PENDING_REVIEW';

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
              runSpacing: 6,
              children: [
                for (final st in const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL'])
                  ChoiceChip(
                    label: Text(F.humanize(st)),
                    selected: _state == st,
                    onSelected: (_) => setState(() => _state = st),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView(
              value: requests,
              onRetry: () => ref.invalidate(approvalQueueProvider(_state)),
              isEmpty: (rows) => (rows as List).isEmpty,
              builder: (context, rows) {
                final list = List.of(rows as List);
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(approvalQueueProvider(_state)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _RequestCard(
                      row: Map.of(list[i] as Map),
                      activeFilter: _state,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.row, required this.activeFilter});
  final Map row;
  final String activeFilter;
  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  var _submitting = false;
  var _docsVerified = false;

  void _refreshAll(WidgetRef ref) {
    for (final s in const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL']) {
      ref.invalidate(approvalQueueProvider(s));
    }
    if (!const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL'].contains(widget.activeFilter)) {
      ref.invalidate(approvalQueueProvider(widget.activeFilter));
    }
  }

  Future<void> _emitNotification(String title, String body) async {
    try {
      final db = Supabase.instance.client;
      await db.from('notifications').insert({
        'title': title,
        'body': body,
        'user_id': db.auth.currentUser?.id,
      });
    } catch (_) {}
  }

  Future<void> _openAdminGmail(Map row) async {
    final adminEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final refCode = (row['reference_code'] ?? row['id'] ?? '').toString();
    final name = (row['requester_name'] ?? row['institution_name'] ?? 'Applicant').toString();
    final email = (row['requester_email'] ?? '').toString();
    final role = (row['requested_role'] ?? row['kind'] ?? '').toString();
    final docInfo = (row['document_url'] ?? row['documents'] ?? row['drive_url'] ?? 'Attached during onboarding / 15 GB Hybrid Drive').toString();
    final subject = Uri.encodeComponent('KSMS Access Request [$refCode] - $name');
    final body = Uri.encodeComponent(
      'Official KSMS Access Request Details\n'
      '-----------------------------------\n'
      'Reference Code: $refCode\n'
      'Applicant / School: $name\n'
      'Email: $email\n'
      'Requested Role / Type: $role\n'
      'Documents / Drive: $docInfo\n'
      'Portal Link: https://th68481-sketch.github.io/KSMS-Tanveer/\n',
    );
    final uri = Uri.parse('mailto:$adminEmail?subject=$subject&body=$body');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openVerifyModal(BuildContext context, WidgetRef ref, Map row) {
    final refCode = (row['reference_code'] ?? row['id'] ?? '').toString();
    final name = (row['requester_name'] ?? row['institution_name'] ?? 'Applicant').toString();
    final email = (row['requester_email'] ?? '').toString();
    final role = (row['requested_role'] ?? row['kind'] ?? '').toString();
    final docInfo = (row['document_url'] ?? row['documents'] ?? row['drive_url'] ?? 'Verification documents & 15 GB Hybrid Drive folder').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify Request & Documents', style: Theme.of(ctx2).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('Reference: $refCode'),
              Text('Applicant / School: $name'),
              Text('Email: $email'),
              Text('Role / Type: $role'),
              const SizedBox(height: 8),
              Text('Documents / 15 GB Drive: $docInfo', style: Theme.of(ctx2).textTheme.bodySmall),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _docsVerified,
                title: const Text('Documents & details verified by Admin'),
                onChanged: (v) {
                  setLocal(() => _docsVerified = v ?? false);
                  setState(() => _docsVerified = v ?? false);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openAdminGmail(row),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Send to Admin Gmail'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx2);
                      _decide(context, ref, 'APPROVE');
                    },
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx2);
                      _decide(context, ref, 'REJECT');
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decide(BuildContext context, WidgetRef ref, String decision) async {
    if (_submitting) return;
    final ctrl = TextEditingController();
    final label = decision == 'APPROVE'
        ? 'Approve Request'
        : (decision == 'REJECT' ? 'Reject Request' : 'Request More Information');
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Remarks / Reason',
            hintText: 'Enter reason or note...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? label : ctrl.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;

    setState(() => _submitting = true);
    final reqId = widget.row['id'];
    final refCode = (widget.row['reference_code'] ?? reqId ?? '').toString();
    final nextState = decision == 'APPROVE'
        ? 'APPROVED'
        : (decision == 'REJECT' ? 'REJECTED' : 'NEEDS_INFORMATION');

    try {
      await ref.read(approvalRepositoryProvider).decide(
            requestId: reqId,
            decision: decision,
            reason: reason,
          );
      await _emitNotification('Request $nextState ($refCode)', reason);
      if (context.mounted) showSnack(context, 'Submitted & Notified: $nextState');
    } catch (_) {
      try {
        await ref.read(approvalRepositoryProvider).directStateUpdate(reqId, nextState, reason);
        await _emitNotification('Request $nextState ($refCode)', reason);
        if (context.mounted) showSnack(context, 'Updated & Notified: $nextState');
      } catch (e2) {
        try {
          final db = Supabase.instance.client;
          await db.from('access_requests').update({
            'state': nextState,
            'status': nextState,
            'decision_reason': reason,
          }).eq('id', reqId);
          await _emitNotification('Request $nextState ($refCode)', reason);
          if (context.mounted) showSnack(context, 'Saved & Notified: $nextState');
        } catch (e3) {
          if (context.mounted) {
            showSnack(context, 'Submit failed: ${e3.toString()}', error: true);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
      _refreshAll(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = context as WidgetRef;
    final l = AppLocalizations.of(context)!;
    final row = widget.row;
    final isSchool = row['kind'] == 'SCHOOL_REGISTRATION';
    final title = isSchool
        ? (row['institution_name']?.toString() ?? 'School Request')
        : '${row['requester_name'] ?? ''} -> ${row['requested_role']?.toString() ?? ''}';
    final st = (row['state'] ?? row['status'] ?? 'PENDING_REVIEW').toString();
    final canAct = st == 'PENDING_REVIEW' ||
        st == 'REQUESTED' ||
        st == 'SUBMITTED' ||
        st == 'PENDING' ||
        st == 'NEEDS_INFORMATION';

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
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                ),
                if (_docsVerified)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Chip(label: Text('Docs Verified')),
                  ),
                StatusChip(status: st, dense: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${row['reference_code'] ?? ''} . ${row['requester_email'] ?? ''} . ${F.date(F.tryParseDate(row['submitted_at']?.toString()))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Verify Details & Docs',
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  onPressed: () => _openVerifyModal(context, ref, row),
                ),
                IconButton(
                  tooltip: 'Send Details to Admin Gmail',
                  icon: const Icon(Icons.mail_outline, size: 18),
                  onPressed: () => _openAdminGmail(row),
                ),
                IconButton(
                  tooltip: 'Copy Reference',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    final c = (row['reference_code'] ?? row['id'] ?? '').toString();
                    Clipboard.setData(ClipboardData(text: c));
                    showSnack(context, 'Copied: $c');
                  },
                ),
                IconButton(
                  tooltip: 'Delete Request',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: _submitting
                      ? null
                      : () async {
                          try {
                            await ref.read(approvalRepositoryProvider).deleteRequest(row['id']);
                            await _emitNotification('Request Deleted', 'Removed request ${row['reference_code'] ?? row['id']}');
                            if (context.mounted) showSnack(context, 'Deleted & Notified');
                            _refreshAll(ref);
                          } catch (e) {
                            if (context.mounted) showSnack(context, e.toString(), error: true);
                          }
                        },
                ),
                if (canAct) ...[
                  FilledButton.tonal(
                    onPressed: _submitting ? null : () => _decide(context, ref, 'APPROVE'),
                    child: Text(_submitting ? 'Saving...' : l.appr_approve),
                  ),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _decide(context, ref, 'REJECT'),
                    child: Text(l.appr_reject),
                  ),
                  TextButton(
                    onPressed: _submitting ? null : () => _decide(context, ref, 'REQUEST_INFO'),
                    child: Text(l.appr_requestInfo),
                  ),
                ] else
                  Text(
                    '${l.common_status}: ${row['decision_reason'] ?? st}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
