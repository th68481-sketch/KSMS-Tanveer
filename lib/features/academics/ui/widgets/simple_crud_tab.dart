import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/common.dart';
import '../../data/academics_repository.dart';
import '../../providers/academics_providers.dart';

typedef RowBuilder = Map<String, dynamic> Function();

/// Generic CRUD tab used across academic setup and simple operations modules.
class SimpleCrudTab extends ConsumerWidget {
  const SimpleCrudTab({
    super.key,
    required this.table,
    required this.rows,
    required this.columns,
    required this.title,
    required this.formTitle,
    required this.fieldBuilder,
    this.rowFromControllers,
    this.canDelete = true,
    this.emptyLabel,
  });

  final String table;
  final AsyncValue<List<Map<String, dynamic>>> rows;
  final List<(String, String)> columns; // (key, label)
  final String title;
  final String formTitle;
  final List<Widget> Function(BuildContext) fieldBuilder;
  final RowBuilder? rowFromControllers;
  final bool canDelete;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(academicsRepositoryProvider);
    return AsyncView<List<Map<String, dynamic>>>(
      value: rows,
      onRetry: () {},
      isEmpty: (r) => r.isEmpty,
      builder: (context, data) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                FilledButton.icon(
                  onPressed: () => _addDialog(context, ref, repo),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  for (final r in data)
                    Card(
                      child: ListTile(
                        dense: true,
                        title: Text(
                          columns.take(2).map((c) => _val(r, c.$1)).join(' · '),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          columns.skip(2).map((c) => '${c.$2}: ${_val(r, c.$1)}').join('  ·  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: canDelete
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () async {
                                  final ok = await confirmAction(
                                    context,
                                    title: 'Remove',
                                    message: 'Remove this record?',
                                    destructive: true,
                                  );
                                  if (ok) {
                                    try {
                                      await repo.delete(table, r['id'] as String);
                                      ref.invalidate(academicYearsProvider);
                                      ref.invalidate(classesProvider);
                                      ref.invalidate(sectionsProvider);
                                      ref.invalidate(subjectsProvider);
                                      ref.invalidate(holidaysProvider);
                                      ref.invalidate(gradingScalesProvider);
                                    } catch (e) {
                                      if (context.mounted) showSnack(context, e.toString(), error: true);
                                    }
                                  }
                                },
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _val(Map<String, dynamic> r, String key) {
    final v = r[key];
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (key.contains('date')) return F.date(DateTime.tryParse(v.toString()));
    return v.toString();
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref, AcademicsRepository repo) async {
    await showFormSheet(
      context,
      title: formTitle,
      formBuilder: (ctx) => Column(children: fieldBuilder(ctx)),
      onSubmit: () async {
        final build = rowFromControllers;
        if (build == null) return;
        try {
          await repo.insert(table, build());
          ref.invalidate(academicYearsProvider);
          ref.invalidate(classesProvider);
          ref.invalidate(sectionsProvider);
          ref.invalidate(subjectsProvider);
          ref.invalidate(holidaysProvider);
          ref.invalidate(gradingScalesProvider);
        } catch (e) {
          if (context.mounted) showSnack(context, e.toString(), error: true);
        }
      },
    );
  }
}
