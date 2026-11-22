import 'package:flutter/material.dart';

class FinanceGovScreen extends StatelessWidget {
  const FinanceGovScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Finance')),
      body: const Center(child: Text('Grants, Budgets, Expense Approval')),
    );
  }
}
