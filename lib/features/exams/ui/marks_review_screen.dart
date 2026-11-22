import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarksReviewScreen extends ConsumerWidget {
  final String examId;
  const MarksReviewScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marks Review')),
      body: const Center(child: Text('Approval Workflow')),
    );
  }
}
