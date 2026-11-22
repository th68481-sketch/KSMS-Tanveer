import 'package:flutter/material.dart';

class FeeCounterScreen extends StatelessWidget {
  const FeeCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Counter')),
      body: const Center(child: Text('Invoice & Receipt Collector')),
    );
  }
}
