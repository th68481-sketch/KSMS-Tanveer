import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exams_providers.dart';

class ExamSetupScreen extends ConsumerWidget {
  const ExamSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Setup')),
      body: const Center(child: Text('Exam Setup Content')),
    );
  }
}
