import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/ksms_table.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/session_controller.dart';
import '../data/student_repository.dart';
import '../providers/student_providers.dart';

class StudentDirectoryScreen extends ConsumerStatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  ConsumerState<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends ConsumerState<StudentDirectoryScreen> {
  String? _sectionFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider).valueOrNull;
    final tenantId = session?.activeTenantId;
    final campusId = session?.activeCampusId;
    final canWrite = session?.can(Permissions.studentsWrite) ?? false;

    final scope = tenantId == null
        ? null
        : (tenantId: tenantId, campusId: campusId, sectionId: _sectionFilter);
    final students = scope == null ? const AsyncValue<List<Map<String, dynamic>>>.loading() : ref.watch(studentListProvider(scope));

    return Scaffold(
      appBar: AppBar(title: Text(l.students_title)),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _newStudentDialog(context),
              icon: const Icon(Icons.person_add),
              label: Text(l.students_new),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AsyncView<List<Map<String, dynamic>>>(
          value: students,
          onRetry: () => ref.invalidate(studentListProvider),
          isEmpty: (rows) => rows.isEmpty,
          builder: (context, rows) {
            final displayRows = rows.map<Map<String, dynamic>>((s) {
              final active = (((s['enrollments'] as List?) ?? const [])
                      .cast<Map<String, dynamic>>()
                      .where((e) => e['status'] == 'ACTIVE')
                      .toList())
                  .firstOrNull;
              return {
                'id': s['id'],
                'admission_no': s['admission_no'],
                'full_name': s['full_name'],
                'gender': F.humanize((s['gender'] as String?) ?? ''),
                'dob': F.date(F.tryParseDate(s['date_of_birth'] as String?)),
                'class': (active?['classes'] as Map?)?['name'] ?? '—',
                'section': (active?['sections'] as Map?)?['name'] ?? '—',
                'roll_no': active?['roll_no'] ?? '—',
                'status': s['status'],
              };
            }).toList();

            return KsmsTable(
              searchHint: l.common_search,
              onRowTap: (r) => context.push(Routes.studentProfile(r['id'] as String)),
              columns: [
                KsmsColumn(key: 'admission_no', label: l.students_admissionNo),
                KsmsColumn(key: 'full_name', label: l.common_name, size: ColumnSize.L),
                KsmsColumn(key: 'class', label: l.students_class),
                KsmsColumn(key: 'section', label: l.students_section),
                KsmsColumn(key: 'roll_no', label: l.students_roll, numeric: true),
                KsmsColumn(key: 'status', label: l.common_status, builder: (_, r) => StatusChip(status: (r['status'] as String?) ?? '', dense: true)),
              ],
              rows: displayRows,
            );
          },
        ),
      ),
    );
  }

  Future<void> _newStudentDialog(BuildContext context) async {
    final nameC = TextEditingController();
    final dobC = TextEditingController();
    final admC = TextEditingController();
    final bFormC = TextEditingController();
    var gender = Gender.male;

    final session = ref.read(sessionProvider).valueOrNull!;
    final tenantId = session.activeTenantId!;
    final campusId = session.activeCampusId ?? '';

    final ok = await showFormSheet(
      context,
      title: AppLocalizations.of(context)!.students_new,
      formBuilder: (ctx) => Column(
        children: [
          TextFormField(controller: nameC, decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.common_name), validator: V.required),
          const SizedBox(height: 12),
          DropdownButtonFormField<Gender>(
            value: gender,
            decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.students_gender),
            items: Gender.values
                .map((g) => DropdownMenuItem(value: g, child: Text(F.humanize(g.value))))
                .toList(),
            onChanged: (v) => gender = v ?? Gender.male,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dobC,
            readOnly: true,
            decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.students_dob),
            onTap: () async {
              final d = await showDatePicker(context: ctx, firstDate: DateTime(1990), lastDate: DateTime.now());
              if (d != null) dobC.text = d.toIso8601String().substring(0, 10);
            },
            validator: V.required,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: admC, decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.students_admissionNo)),
          const SizedBox(height: 12),
          TextFormField(controller: bFormC, decoration: InputDecoration(labelText: 'B-Form / CNIC'), validator: V.cnic),
        ],
      ),
      onSubmit: () async {
        final repo = ref.read(studentRepositoryProvider);
        try {
          final studentId = await repo.createStudent({
            'tenant_id': tenantId,
            'campus_id': campusId,
            if (admC.text.trim().isNotEmpty) 'admission_no': admC.text.trim(),
            'full_name': nameC.text.trim(),
            'gender': gender.value,
            'date_of_birth': dobC.text.trim(),
            if (bFormC.text.trim().isNotEmpty) 'b_form_no': bFormC.text.trim(),
          });
          if (context.mounted) {
            showSnack(context, studentId);
            ref.invalidate(studentListProvider);
          }
        } catch (e) {
          if (context.mounted) showSnack(context, e.toString(), error: true);
        }
      },
    );
    if (!ok) return;
  }
}
