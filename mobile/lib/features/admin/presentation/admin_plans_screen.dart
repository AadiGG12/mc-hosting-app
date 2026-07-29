import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminPlansScreen extends StatelessWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Plans')),
      body: const Center(child: Text('Plans list')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/plans/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
