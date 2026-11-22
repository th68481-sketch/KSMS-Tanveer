import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../providers/assignments_providers.dart';
import '../providers/academics_providers.dart';
import 'widgets/simple_crud_tab.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(assignmentsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Assignments')),
      body: SimpleCrudTab(
        table: 'teacher_assignments',
        rows: rows,
        title: 'Assignments',
        formTitle: 'New assignment',
        columns: const [
          ('staff/full_name', 'Teacher'),
          ('classes/name', 'Class'),
          ('sections/name', 'Section'),
          ('subjects/name', 'Subject')
        ],
        fieldBuilder: (BuildContext ctx) {
            final staff = TextEditingController();
            final klass = TextEditingController();
            return [
                TextFormField(controller: staff, decoration: const InputDecoration(labelText: 'Staff ID')),
                TextFormField(controller: klass, decoration: const InputDecoration(labelText: 'Class ID')),
            ];
        },
      ),
    );
  }
}
