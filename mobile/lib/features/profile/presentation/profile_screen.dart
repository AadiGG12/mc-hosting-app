import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../updates/data/update_service.dart';
import '../../updates/presentation/update_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _checkUpdates(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking GitHub for updates...')),
    );

    final info = await UpdateService.checkForUpdates();
    if (!context.mounted) return;

    if (info != null && info.isNewerVersion) {
      showDialog(
        context: context,
        builder: (context) => UpdateDialog(releaseInfo: info),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are on the latest version of RenCloud!'),
          backgroundColor: AppTheme.primaryAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Account & Profile'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Card(
              color: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                      child: Text(
                        (user.firstName.isNotEmpty ? user.firstName[0] : 'U').toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}'.trim().isNotEmpty
                                ? '${user.firstName} ${user.lastName}'
                                : user.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'SETTINGS & CONTROLS',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          if (isAdmin)
            Card(
              color: AppTheme.cardBg,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                title: const Text('Admin Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Manage hosting plans & orders', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push('/admin'),
              ),
            ),
          Card(
            color: AppTheme.cardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListTile(
              leading: const Icon(Icons.system_update_rounded, color: AppTheme.secondary),
              title: const Text('Check for OTA Updates', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Compare with GitHub Releases', style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _checkUpdates(context),
            ),
          ),
          Card(
            color: AppTheme.cardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
