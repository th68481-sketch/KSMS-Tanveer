import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoticesBoardScreen extends ConsumerWidget {
  const NoticesBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices Board')),
      body: const Center(child: Text('Notices Board Screen')),
    );
  }
}
