import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../providers/academics_providers.dart';
import 'widgets/simple_crud_tab.dart';

class AcademicSetupScreen extends StatelessWidget {
  const AcademicSetupScreen({super.key});

  static const _tabs = ['Years', 'Terms', 'Classes', 'Sections', 'Subjects', 'Holidays', 'Grading'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academic Setup'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final t in _tabs) Tab(text: t)],
          ),
        ),
        body: const TabBarView(
          children: [
            _YearsTab(),
            _TermsTab(),
            _ClassesTab(),
            _SectionsTab(),
            _SubjectsTab(),
            _HolidaysTab(),
            _ScalesTab(),
          ],
        ),
      ),
    );
  }
}

TextEditingController _ctl([String seed = '']) => TextEditingController(text: seed);

class _YearsTab extends ConsumerWidget {
  const _YearsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(academicYearsProvider);
    return SimpleCrudTab(
      table: 'academic_years',
      rows: rows,
      title: 'Academic years',
      formTitle: 'New academic year',
      columns: const [('name', 'Name'), ('start_date', 'Start'), ('end_date', 'End'), ('is_current', 'Current')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final start = _ctl();
        final end = _ctl();
        final current = ValueNotifier<bool>(false);
        return [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name (e.g. 2026-27)'), validator: (v) => V.required(v)),
          _DateField(controller: start, label: 'Start date'),
          _DateField(controller: end, label: 'End date'),
          _SwitchField(notifier: current, label: 'Set as current year'),
        ];
      },
    );
  }
}

class _TermsTab extends ConsumerWidget {
  const _TermsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
    final yearId = ref.watch(currentYearProvider)?['id'] as String?;
    final rows = yearId == null ? const AsyncValue<List<Map<String, dynamic>>>.data([]) : ref.watch(termsProvider(yearId));
    return SimpleCrudTab(
      table: 'terms',
      rows: rows,
      title: 'Terms',
      formTitle: 'New term',
      columns: const [('name', 'Name'), ('start_date', 'Start'), ('end_date', 'End')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final start = _ctl();
        final end = _ctl();
        final year = ValueNotifier<String?>(yearId);
        return [
          _DropdownField(
            notifier: year,
            label: 'Academic year',
            items: {for (final y in years) y['id'] as String: y['name'].toString()},
          ),
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Term name'), validator: (v) => V.required(v)),
          _DateField(controller: start, label: 'Start date'),
          _DateField(controller: end, label: 'End date'),
        ];
      },
    );
  }
}

class _ClassesTab extends ConsumerWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(classesProvider);
    return SimpleCrudTab(
      table: 'classes',
      rows: rows,
      title: 'Classes',
      formTitle: 'New class',
      columns: const [('name', 'Name'), ('numeric_level', 'Level')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final level = _ctl();
        return [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Class name'), validator: (v) => V.required(v)),
          TextFormField(controller: level, decoration: const InputDecoration(labelText: 'Numeric level'), keyboardType: TextInputType.number, validator: (v) => V.nonNegativeNum(v)),
        ];
      },
    );
  }
}

class _SectionsTab extends ConsumerWidget {
  const _SectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(sectionsProvider);
    final classes = ref.watch(classesProvider).valueOrNull ?? const [];
    return SimpleCrudTab(
      table: 'sections',
      rows: rows,
      title: 'Sections',
      formTitle: 'New section',
      columns: const [('name', 'Section'), ('classes/name', 'Class'), ('capacity', 'Capacity')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final capacity = _ctl();
        final klass = ValueNotifier<String?>(null);
        return [
          _DropdownField(
            notifier: klass,
            label: 'Class',
            items: {for (final c in classes) c['id'] as String: c['name'].toString()},
          ),
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Section name (e.g. A)'), validator: (v) => V.required(v)),
          TextFormField(controller: capacity, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number, validator: (v) => V.positiveNum(v)),
        ];
      },
    );
  }
}

class _SubjectsTab extends ConsumerWidget {
  const _SubjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(subjectsProvider);
    return SimpleCrudTab(
      table: 'subjects',
      rows: rows,
      title: 'Subjects',
      formTitle: 'New subject',
      columns: const [('name', 'Name'), ('code', 'Code')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final code = _ctl();
        return [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Subject name'), validator: (v) => V.required(v)),
          TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Code'), textCapitalization: TextCapitalization.characters),
        ];
      },
    );
  }
}

class _HolidaysTab extends ConsumerWidget {
  const _HolidaysTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(holidaysProvider);
    return SimpleCrudTab(
      table: 'holidays',
      rows: rows,
      title: 'Holidays',
      formTitle: 'New holiday',
      columns: const [('holiday_date', 'Date'), ('name', 'Name')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final date = _ctl();
        return [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Holiday name'), validator: (v) => V.required(v)),
          _DateField(controller: date, label: 'Date'),
        ];
      },
    );
  }
}

class _ScalesTab extends ConsumerWidget {
  const _ScalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(gradingScalesProvider);
    return SimpleCrudTab(
      table: 'grading_scales',
      rows: rows,
      title: 'Grading scales',
      formTitle: 'New grading scale',
      columns: const [('name', 'Name'), ('bands', 'Bands')],
      fieldBuilder: (BuildContext ctx) {
        final name = _ctl();
        final bands = _ctl();
        return [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Scale name'), validator: (v) => V.required(v)),
          TextFormField(
            controller: bands,
            decoration: const InputDecoration(
              labelText: 'Bands (JSON)',
              helperText: 'e.g. [{"grade":"A+","min":90,"max":100,"gpa":4.0}]',
            ),
            maxLines: 3,
            validator: (v) {
              if (V.required(v) != null) return 'Required';
              try {
                final parsed = jsonDecode(v!);
                return parsed is List ? null : 'Must be a JSON array';
              } catch (_) {
                return 'Invalid JSON';
              }
            },
          ),
        ];
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
      validator: (v) => V.required(v),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) controller.text = F.date(picked);
      },
    );
  }
}

class _SwitchField extends StatelessWidget {
  const _SwitchField({required this.notifier, required this.label});
  final ValueNotifier<bool> notifier;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: (v) => notifier.value = v,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.notifier, required this.label, required this.items});
  final ValueNotifier<String?> notifier;
  final String label;
  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, value, _) => DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
        onChanged: (v) => notifier.value = v,
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }
}
