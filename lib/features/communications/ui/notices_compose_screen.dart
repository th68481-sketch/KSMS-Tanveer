import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoticesComposeScreen extends ConsumerWidget {
  const NoticesComposeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compose Notice')),
      body: const Center(child: Text('Notices Compose Screen')),
    );
  }
}
