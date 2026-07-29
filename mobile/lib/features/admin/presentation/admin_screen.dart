import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        children: [
          ListTile(title: const Text('Manage Plans'), onTap: () => context.push('/admin/plans')),
          ListTile(title: const Text('Manage Orders'), onTap: () => context.push('/admin/orders')),
        ],
      )
    );
  }
}
