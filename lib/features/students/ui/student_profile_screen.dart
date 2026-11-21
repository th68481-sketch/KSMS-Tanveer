import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/domain.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../academics/providers/academics_providers.dart';
import '../../auth/providers/session_controller.dart';
import '../data/student_repository.dart';
import '../providers/student_providers.dart';

/// Student 360° view: overview, enrollment history, guardians, attendance,
/// fees, results and private documents — all real authorized data.
class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key, required this.studentId});
  final String studentId;

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 7, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final student = ref.watch(studentDetailProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(student.valueOrNull?['full_name'] as String? ?? l.students_360),
        actions: [
          IconButton(
            tooltip: l.students_duplicates,
            onPressed: () => _checkDuplicates(context),
            icon: const Icon(Icons.person_search),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: l.common_view),
            Tab(text: l.students_enrollments),
            Tab(text: l.students_guardians),
            Tab(text: l.students_attendance),
            Tab(text: l.students_fees),
            Tab(text: l.students_results),
            Tab(text: l.students_documents),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(studentId: widget.studentId),
          _EnrollmentsTab(studentId: widget.studentId),
          _GuardiansTab(studentId: widget.studentId),
          _AttendanceTab(studentId: widget.studentId),
          _FeesTab(studentId: widget.studentId),
          _ResultsTab(studentId: widget.studentId),
          _DocumentsTab(studentId: widget.studentId),
        ],
      ),
    );
  }

  Future<void> _checkDuplicates(BuildContext context) async {
    final s = ref.read(studentDetailProvider(widget.studentId)).valueOrNull;
    if (s == null) return;
    try {
      final dupes = await ref.read(studentRepositoryProvider).findDuplicates(
            tenantId: s['tenant_id'] as String,
            name: (s['full_name'] as String?) ?? '',
            dob: s['date_of_birth'] as String?,
            bForm: s['b_form_no'] as String?,
          );
      final others = dupes.where((d) => d['id'] != widget.studentId).toList();
      if (!context.mounted) return;
      if (others.isEmpty) {
        showSnack(context, 'No duplicates found');
        return;
      }
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx)!.students_duplicates),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in others)
                ListTile(
                  title: Text(d['full_name'] as String? ?? ''),
                  subtitle: Text('${d['admission_no']}'),
                  onTap: () => Navigator.pop(ctx, d['id'] as String),
                ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
        ),
      );
      if (selected == null) return;
      if (!context.mounted) return;
      final ok = await confirmAction(
        context,
        title: AppLocalizations.of(context)!.students_merge,
        message: AppLocalizations.of(context)!.students_mergeConfirm,
        confirmLabel: AppLocalizations.of(context)!.students_merge,
      );
      if (!ok) return;
      await ref.read(studentRepositoryProvider).merge(widget.studentId, selected);
      if (context.mounted) showSnack(context, 'Merged');
      ref.invalidate(studentDetailProvider(widget.studentId));
    } catch (e) {
      if (context.mounted) showSnack(context, e.toString(), error: true);
    }
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final student = ref.watch(studentDetailProvider(studentId));

    return AsyncView<Map<String, dynamic>?>(
      value: student,
      onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
      isEmpty: (d) => d == null,
      builder: (context, sRaw) {
        final s = sRaw;
        if (s == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: KsmsColors.navy100,
                          child: Text((s['full_name'] as String?)?.isNotEmpty == true
                              ? (s['full_name'] as String)[0]
                              : '?'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['full_name'] as String? ?? '',
                                  style: Theme.of(context).textTheme.titleLarge),
                              Text('${s['admission_no']}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        StatusChip(status: (s['status'] as String?) ?? ''),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        _kv(l.students_gender, F.humanize((s['gender'] as String?) ?? '')),
                        _kv(l.students_dob, F.date(F.tryParseDate(s['date_of_birth'] as String?))),
                        _kv('B-Form', (s['b_form_no'] as String?) ?? '—'),
                        _kv(l.common_city, (s['address'] as String?) ?? '—'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kv(String k, String v) => SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _EnrollmentsTab extends ConsumerWidget {
  const _EnrollmentsTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider).valueOrNull;
    final enrollments = ref.watch(studentEnrollmentsProvider(studentId));

    return AsyncView<List<Map<String, dynamic>>>(
      value: enrollments,
      onRetry: () => ref.invalidate(studentEnrollmentsProvider(studentId)),
      isEmpty: (r) => r.isEmpty,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session?.can(Permissions.studentsWrite) ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _promote(context, ref, rows),
                  icon: const Icon(Icons.upgrade),
                  label: Text(l.students_promote),
                ),
                OutlinedButton.icon(
                  onPressed: () => _leave(context, ref, rows, 'TRANSFERRED'),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l.students_transfer),
                ),
                OutlinedButton.icon(
                  onPressed: () => _leave(context, ref, rows, 'WITHDRAWN'),
                  icon: const Icon(Icons.logout),
                  label: Text(l.students_withdraw),
                ),
              ]),
            ),
            ...rows.map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.history_edu),
                    title: Text(
                      '${(e['classes'] as Map?)?['name'] ?? '—'} · ${(e['sections'] as Map?)?['name'] ?? '—'}'
                      ' · ${(e['academic_years'] as Map?)?['name'] ?? ''}',
                    ),
                    subtitle: Text(
                      '${l.students_roll}: ${e['roll_no'] ?? '—'} · ${F.date(F.tryParseDate(e['admission_date'] as String?))}'
                      '${e['leaving_certificate_no'] != null ? ' · ${e['leaving_certificate_no']}' : ''}',
                    ),
                    trailing: StatusChip(status: (e['status'] as String?) ?? '', dense: true),
                  ),
                )),
          ],
        ),
      );
    }

  Future<void> _promote(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> rows) async {
    final active = rows.where((e) => e['status'] == 'ACTIVE').toList();
    if (active.isEmpty) return;
    final years = ref.read(academicYearsProvider).valueOrNull ?? [];
    final classes = ref.read(classesProvider).valueOrNull ?? [];
    final sections = ref.read(sectionsProvider).valueOrNull ?? [];
    if (years.isEmpty || classes.isEmpty) return;
    final latestYear = years.first['id'] as String;
    String? yearId = latestYear, classId, sectionId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.students_promote),
        content: StatefulBuilder(builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: yearId,
              decoration: const InputDecoration(labelText: 'Academic year'),
              items: years.map((y) => DropdownMenuItem(value: y['id'] as String, child: Text(y['name'] as String))).toList(),
              onChanged: (v) => setS(() => yearId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Class'),
              items: classes.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
              onChanged: (v) => setS(() => classId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Section'),
              items: sections.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
              onChanged: (v) => setS(() => sectionId = v),
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promote')),
        ],
      ),
    );
    if (ok != true || classId == null || sectionId == null) return;
    try {
      final msg = await ref.read(studentRepositoryProvider).promote(
            toYear: yearId!,
            toClass: classId!,
            toSection: sectionId!,
            enrollmentIds: active.map((e) => e['id'] as String).toList(),
          );
      if (context.mounted) showSnack(context, 'Promoted: $msg');
      ref.invalidate(studentEnrollmentsProvider(studentId));
    } catch (e) {
      if (context.mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> rows, String status) async {
    final active = rows.where((e) => e['status'] == 'ACTIVE').toList();
    if (active.isEmpty) return;
    final reasonC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'TRANSFERRED'
            ? AppLocalizations.of(ctx)!.students_transfer
            : AppLocalizations.of(ctx)!.students_withdraw),
        content: TextField(
          controller: reasonC,
          maxLines: 2,
          decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.common_reason),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true || reasonC.text.trim().isEmpty) return;
    try {
      final cert = await ref.read(studentRepositoryProvider).issueLeavingCertificate(
            enrollmentId: active.first['id'] as String,
            finalStatus: status,
            reason: reasonC.text.trim(),
          );
      if (context.mounted) showSnack(context, '${AppLocalizations.of(context)!.students_certNo}: $cert');
      ref.invalidate(studentEnrollmentsProvider(studentId));
    } catch (e) {
      if (context.mounted) showSnack(context, e.toString(), error: true);
    }
  }
}

class _GuardiansTab extends ConsumerStatefulWidget {
  const _GuardiansTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_GuardiansTab> createState() => _GuardiansTabState();
}

class _GuardiansTabState extends ConsumerState<_GuardiansTab> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider).valueOrNull;
    final canWrite = session?.can(Permissions.guardiansWrite) ?? false;
    final guardians = ref.watch(studentGuardiansProvider(widget.studentId));

    return AsyncView<List<Map<String, dynamic>>>(
      value: guardians,
      onRetry: () => ref.invalidate(studentGuardiansProvider(widget.studentId)),
      isEmpty: (r) => r.isEmpty,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (canWrite)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => _linkGuardian(context),
                icon: const Icon(Icons.link),
                label: Text(l.students_addGuardian),
              ),
            ),
          ...rows.map((g) {
            final gd = g['guardians'] as Map? ?? {};
            return Card(
              child: ListTile(
                leading: const Icon(Icons.family_restroom),
                title: Text('${gd['full_name'] ?? ''} · ${F.humanize((g['relationship'] as String?) ?? '')}'),
                subtitle: Text(
                  '${gd['phone'] ?? ''}'
                  ' · ${l.students_primary}: ${g['is_primary'] == true ? l.common_yes : l.common_no}'
                  ' · ${l.students_portalAccess}: ${g['portal_access'] == true ? l.common_yes : l.common_no}'
                  ' · ${l.students_verified}: ${g['verified'] == true ? l.common_yes : l.common_no}',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _linkGuardian(BuildContext context) async {
    final session = ref.read(sessionProvider).valueOrNull!;
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final cnicC = TextEditingController();
    var relationship = 'FATHER';
    var primary = true, pickup = true, portal = true;

    final ok = await showFormSheet(
      context,
      title: AppLocalizations.of(context)!.students_addGuardian,
      formBuilder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Column(
        children: [
          TextFormField(controller: nameC, decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.common_name), validator: V.required),
          const SizedBox(height: 12),
          TextFormField(controller: phoneC, decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.common_phone), validator: V.phone),
          const SizedBox(height: 12),
          TextFormField(controller: cnicC, decoration: InputDecoration(labelText: 'CNIC'), validator: V.cnic),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: relationship,
            decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.students_relationship),
            items: const [
              DropdownMenuItem(value: 'FATHER', child: Text('Father')),
              DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
              DropdownMenuItem(value: 'GUARDIAN', child: Text('Guardian')),
              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
            ],
            onChanged: (v) => setS(() => relationship = v ?? 'FATHER'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(AppLocalizations.of(ctx)!.students_primary),
            value: primary,
            onChanged: (v) => setS(() => primary = v),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(ctx)!.students_canPickup),
            value: pickup,
            onChanged: (v) => setS(() => pickup = v),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(ctx)!.students_portalAccess),
            value: portal,
            onChanged: (v) => setS(() => portal = v),
          ),
        ],
      )),
      onSubmit: () async {
        try {
          await ref.read(studentRepositoryProvider).linkGuardian(
                tenantId: session.activeTenantId!,
                studentId: widget.studentId,
                guardianName: nameC.text.trim(),
                phone: phoneC.text.trim(),
                cnic: cnicC.text.trim().isEmpty ? null : cnicC.text.trim(),
                relationship: relationship,
                isPrimary: primary,
                canPickup: pickup,
                portalAccess: portal,
              );
          ref.invalidate(studentGuardiansProvider(widget.studentId));
        } catch (e) {
          if (context.mounted) showSnack(context, e.toString(), error: true);
        }
      },
    );
    if (!ok) return;
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final data = ref.watch(studentAttendanceSummaryProvider(studentId));

    return AsyncView<List<Map<String, dynamic>>>(
      value: data,
      onRetry: () => ref.invalidate(studentAttendanceSummaryProvider(studentId)),
      isEmpty: (r) => r.isEmpty,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows)
            Card(
              child: ListTile(
                title: Text(F.date(DateTime.parse(r['month'] as String))),
                subtitle: Text(
                  '${l.att_present}: ${r['present_days']} · ${l.att_absent}: ${r['absent_days']}'
                  ' · ${l.att_late}: ${r['late_days']} · ${l.att_leave}: ${r['leave_days']}'
                  ' · ${l.common_all}: ${r['total_days']}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeesTab extends ConsumerWidget {
  const _FeesTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final data = ref.watch(studentInvoicesProvider(studentId));

    return AsyncView<List<Map<String, dynamic>>>(
      value: data,
      onRetry: () => ref.invalidate(studentInvoicesProvider(studentId)),
      isEmpty: (r) => r.isEmpty,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows)
            Card(
              child: ListTile(
                title: Text('${r['invoice_no']} · ${r['billing_period']}'),
                subtitle: Text(
                  '${l.fin_gross}: ${F.pkr((r['gross_total'] as num?) ?? 0)} · '
                  '${l.fin_discount}: ${F.pkr((r['discount_total'] as num?) ?? 0)} · '
                  '${l.fin_paid}: ${F.pkr((r['paid_total'] as num?) ?? 0)}',
                ),
                trailing: StatusChip(status: (r['status'] as String?) ?? '', dense: true),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultsTab extends ConsumerWidget {
  const _ResultsTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final data = ref.watch(studentReportCardsProvider(studentId));

    return AsyncView<List<Map<String, dynamic>>>(
      value: data,
      onRetry: () => ref.invalidate(studentReportCardsProvider(studentId)),
      isEmpty: (r) => r.isEmpty,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows)
            Card(
              child: ListTile(
                title: Text((r['exams'] as Map?)?['name'] as String? ?? ''),
                subtitle: Text(
                  '${l.exam_percentage}: ${r['percentage'] ?? '—'} · ${l.exam_grade}: ${r['grade'] ?? '—'}',
                ),
                trailing: StatusChip(status: (r['status'] as String?) ?? '', dense: true),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentsTab extends ConsumerStatefulWidget {
  const _DocumentsTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider).valueOrNull;
    final docs = ref.watch(studentDocumentsProvider(widget.studentId));

    return AsyncView<List<Map<String, dynamic>>>(
      value: docs,
      onRetry: () => ref.invalidate(studentDocumentsProvider(widget.studentId)),
      isEmpty: (r) => r.isEmpty,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session?.can(Permissions.studentsWrite) ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _upload,
                icon: const Icon(Icons.upload_file),
                label: Text(l.common_upload),
              ),
            ),
          ...rows.map((d) => Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(d['filename'] as String? ?? ''),
                  subtitle: Text(F.dateTime(F.tryParseDate(d['uploaded_at'] as String?))),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      try {
                        final url = await ref
                            .read(studentRepositoryProvider)
                            .documentUrl(d['path'] as String);
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(d['filename'] as String? ?? ''),
                              content: SelectableText(url),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) showSnack(context, e.toString(), error: true);
                      }
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _upload() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final f = res?.files.firstOrNull;
    if (f?.bytes == null) return;
    final session = ref.read(sessionProvider).valueOrNull!;
    setState(() => _busy = true);
    try {
      await ref.read(studentRepositoryProvider).uploadStudentDocument(
            tenantId: session.activeTenantId!,
            campusId: session.activeCampusId,
            studentId: widget.studentId,
            filename: f.name,
            bytes: f.bytes!,
            contentType: f.name.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
          );
      ref.invalidate(studentDocumentsProvider(widget.studentId));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
