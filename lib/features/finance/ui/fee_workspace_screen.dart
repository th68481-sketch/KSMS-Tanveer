import 'package:flutter/material.dart';

class FeeWorkspaceScreen extends StatelessWidget {
  const FeeWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Workspace')),
      body: const Center(child: Text('Fee Heads, Plans, Discounts Management')),
    );
  }
}
