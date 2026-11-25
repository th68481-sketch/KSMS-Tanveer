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

  void _refreshAll() {
    for (final s in const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL']) {
      ref.invalidate(approvalQueueProvider(s));
    }
    if (!const ['PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED', 'ALL'].contains(widget.activeFilter)) {
      ref.invalidate(approvalQueueProvider(widget.activeFilter));
    }
  }

  List<String> _extractDocCandidates(Map row) {
    final out = <String>[];
    for (final k in const [
      'evidence_paths',
      'document_paths',
      'document_url',
      'doc_url',
      'drive_url',
      'attachment_url',
      'documents',
      'storage_path',
      'file_path',
    ]) {
      final val = row[k];
      if (val == null) continue;
      if (val is List) {
        for (final item in val) {
          final s = item?.toString().trim() ?? '';
          if (s.isNotEmpty && !out.contains(s)) out.add(s);
        }
      } else {
        final s = val.toString().trim();
        if (s.isNotEmpty && s != '[]' && s != '{}' && !out.contains(s)) out.add(s);
      }
    }
    return out;
  }

  Future<List<String>> _resolveDocumentLinks(Map row) async {
    final candidates = _extractDocCandidates(row);
    final resolved = <String>[];
    final storagePaths = <String>[];

    for (final item in candidates) {
      if (item.startsWith('http://') || item.startsWith('https://')) {
        if (!resolved.contains(item)) resolved.add(item);
      } else {
        storagePaths.add(item);
      }
    }

    if (storagePaths.isNotEmpty) {
      try {
        final signed = await ref.read(approvalRepositoryProvider).evidenceUrls(storagePaths);
        for (final u in signed) {
          final s = u?.toString().trim() ?? '';
          if (s.isNotEmpty && !resolved.contains(s)) resolved.add(s);
        }
      } catch (_) {}
    }

    if (resolved.isEmpty && storagePaths.isNotEmpty) {
      resolved.addAll(storagePaths);
    }
    return resolved;
  }

  Future<void> _openDocLink(String target) async {
    if (target.startsWith('http://') || target.startsWith('https://')) {
      final uri = Uri.tryParse(target);
      if (uri != null) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    }
    await Clipboard.setData(ClipboardData(text: target));
    if (mounted) showSnack(context, 'Document reference copied: $target');
  }

  Future<void> _emitNotification(String title, String body) async {
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;
      await db.from('notifications').insert({
        'user_id': uid,
        'title': title,
        'body': body,
      });
    } catch (_) {}
  }

  Future<void> _openAdminGmail(Map row) async {
    final adminEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final refCode = (row['reference_code'] ?? row['id'] ?? '').toString();
    final name = (row['requester_name'] ?? row['institution_name'] ?? 'Applicant').toString();
    final email = (row['requester_email'] ?? '').toString();
    final role = (row['requested_role'] ?? row['kind'] ?? '').toString();
    final docs = _extractDocCandidates(row).join(', ');
    final docInfo = docs.isNotEmpty ? docs : 'Attached during onboarding / 15 GB Hybrid Drive';
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

  void _openVerifyModal(Map row) {
    final refCode = (row['reference_code'] ?? row['id'] ?? '').toString();
    final name = (row['requester_name'] ?? row['institution_name'] ?? 'Applicant').toString();
    final email = (row['requester_email'] ?? '').toString();
    final role = (row['requested_role'] ?? row['kind'] ?? '').toString();

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
              SelectableText('Reference: $refCode'),
              SelectableText('Applicant / School: $name'),
              SelectableText('Email: $email'),
              SelectableText('Role / Type: $role'),
              const SizedBox(height: 10),
              FutureBuilder<List<String>>(
                future: _resolveDocumentLinks(row),
                builder: (c3, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final links = snap.data ?? const <String>[];
                  if (links.isEmpty) {
                    return const Text(
                      'No document attached — check 15 GB Hybrid Drive folder',
                      style: TextStyle(fontSize: 12),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Documents / Evidence:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      for (final link in links)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: OutlinedButton.icon(
                            onPressed: () => _openDocLink(link),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
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
                      _decide('APPROVE');
                    },
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx2);
                      _decide('REJECT');
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

  Future<void> _deleteCurrentRequest() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final reqId = widget.row['id'];
    final refCode = (widget.row['reference_code'] ?? reqId ?? '').toString();
    try {
      await ref.read(approvalRepositoryProvider).deleteRequest(reqId);
      await _emitNotification('Request Deleted', 'Removed request $refCode');
      if (mounted) showSnack(context, 'Deleted: $refCode');
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Delete failed: ${e.toString()}', error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
      _refreshAll();
    }
  }

  Future<void> _decide(String decision) async {
    if (_submitting) return;
    final ctrl = TextEditingController();
    final titleText = decision == 'APPROVE'
        ? 'Approve Request'
        : (decision == 'REJECT' ? 'Reject Request' : 'Request More Information');
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titleText),
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
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? titleText : ctrl.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

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
      if (mounted) showSnack(context, 'Submitted: $nextState');
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Approval error: ${e.toString()}', error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
      _refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final row = widget.row;
    final isSchool = row['kind'] == 'SCHOOL_REGISTRATION';
    final title = isSchool
        ? (row['institution_name']?.toString() ?? 'School Request')
        : '${row['requester_name'] ?? ''} -> ${row['requested_role']?.toString() ?? ''}';
    final st = (row['state'] ?? row['status'] ?? 'PENDING_REVIEW').toString();
    final docCandidates = _extractDocCandidates(row);
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
                  tooltip: 'Verify Details & Documents',
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  onPressed: () => _openVerifyModal(row),
                ),
                if (docCandidates.isNotEmpty)
                  IconButton(
                    tooltip: 'Open / Copy Document',
                    icon: const Icon(Icons.description_outlined, size: 18),
                    onPressed: () async {
                      final links = await _resolveDocumentLinks(row);
                      if (links.isNotEmpty) await _openDocLink(links.first);
                    },
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
                  onPressed: _submitting ? null : _deleteCurrentRequest,
                ),
                if (canAct) ...[
                  FilledButton.tonal(
                    onPressed: _submitting ? null : () => _decide('APPROVE'),
                    child: Text(_submitting ? 'Saving...' : l.appr_approve),
                  ),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _decide('REJECT'),
                    child: Text(l.appr_reject),
                  ),
                  TextButton(
                    onPressed: _submitting ? null : () => _decide('REQUEST_INFO'),
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
