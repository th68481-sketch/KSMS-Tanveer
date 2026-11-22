import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResultsSummaryScreen extends ConsumerWidget {
  const ResultsSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results Summary')),
      body: const Center(child: Text('Results Summary Screen')),
    );
  }
}
