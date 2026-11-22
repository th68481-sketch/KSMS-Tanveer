import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeeSummaryScreen extends ConsumerWidget {
  const FeeSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Summary')),
      body: const Center(child: Text('Fee Summary Screen')),
    );
  }
}
