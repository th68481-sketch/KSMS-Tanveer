import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/sync_engine.dart';
import '../providers/attendance_providers.dart';

class AttendanceWorkspaceScreen extends ConsumerStatefulWidget {
  const AttendanceWorkspaceScreen({
    super.key,
    required this.tenantId,
    required this.campusId,
    required this.classId,
    required this.sectionId,
    required this.academicYearId,
    required this.sessionId,
  });

  final String tenantId;
  final String campusId;
  final String classId;
  final String sectionId;
  final String academicYearId;
  final String sessionId;

  @override
  ConsumerState<AttendanceWorkspaceScreen> createState() => _AttendanceWorkspaceScreenState();
}

class _AttendanceWorkspaceScreenState extends ConsumerState<AttendanceWorkspaceScreen> {
  final Map<String, String> _attendanceMap = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(attendanceRecordsProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (records) {
          if (_attendanceMap.isEmpty) {
            for (final record in records) {
              _attendanceMap[record['student_id'] as String] = record['status'] as String;
            }
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final studentId = record['student_id'] as String;
              final studentName = record['students']?['full_name'] as String? ?? 'Unknown';

              return ListTile(
                title: Text(studentName),
                trailing: Wrap(
                  spacing: 4,
                  children: ['PRESENT', 'ABSENT', 'LATE', 'LEAVE'].map((status) {
                    final isSelected = _attendanceMap[studentId] == status;
                    return FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _attendanceMap[studentId] = status;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAttendance,
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    
    final records = _attendanceMap.entries.map((e) => {
      'session_id': widget.sessionId,
      'student_id': e.key,
      'status': e.value,
    }).toList();

    await ref.read(syncEngineProvider.notifier).enqueueAttendanceBatch(
      tenantId: widget.tenantId,
      campusId: widget.campusId,
      classId: widget.classId,
      sectionId: widget.sectionId,
      academicYearId: widget.academicYearId,
      sessionDate: DateTime.now().toIso8601String().split('T')[0], // Simplified
      sessionKind: 'MORNING', // Should be dynamic
      records: records,
    );

    setState(() => _isSaving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance enqueued')));
  }
}
