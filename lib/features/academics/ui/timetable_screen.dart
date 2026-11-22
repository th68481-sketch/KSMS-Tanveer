import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timetable_providers.dart';
import '../providers/academics_providers.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Need interactive grid builder
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: const Center(child: Text('Timetable builder - implementation pending')),
    );
  }
}
