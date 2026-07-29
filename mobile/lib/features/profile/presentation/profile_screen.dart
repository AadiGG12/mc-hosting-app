import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              title: Text('${user.firstName} ${user.lastName}'),
              subtitle: Text(user.email),
              leading: const CircleAvatar(child: Icon(Icons.person)),
            ),
          const Divider(),
          if (isAdmin)
            ListTile(
              title: const Text('Admin Panel'),
              leading: const Icon(Icons.admin_panel_settings),
              onTap: () => context.push('/admin'),
            ),
          ListTile(
            title: const Text('Check for Updates'),
            leading: const Icon(Icons.update),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Logout', style: const TextStyle(color: Colors.red)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
    );
  }
}
