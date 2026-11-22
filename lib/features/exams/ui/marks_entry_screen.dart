import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exams_providers.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final String examId;
  const MarksEntryScreen({super.key, required this.examId});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  @override
  Widget build(BuildContext context) {
    final marksAsync = ref.watch(marksProvider(widget.examId));
    return Scaffold(
      appBar: AppBar(title: const Text('Marks Entry')),
      body: marksAsync.when(
        data: (marks) => GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          itemCount: marks.length,
          itemBuilder: (context, index) => Card(child: Text(marks[index]['students']['full_name'])),
        ),
        error: (e, s) => Text('Error: $e'),
        loading: () => const CircularProgressIndicator(),
      ),
    );
  }
}
