import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../updates/data/update_service.dart';
import '../../updates/presentation/update_dialog.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _checkUpdates(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking GitHub for updates...')),
    );
    final info = await UpdateService.checkForUpdates();
    if (!context.mounted) return;
    if (info != null && info.isNewerVersion) {
      showDialog(context: context, builder: (context) => UpdateDialog(releaseInfo: info));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version!'),
            backgroundColor: AppTheme.primaryPurple),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
                        child: Text(
                          (user.firstName.isNotEmpty ? user.firstName[0] : 'U').toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(user.email,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                            if (isAdmin)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('ROOT ADMIN',
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryPurple),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Settings Section
            Text('SETTINGS',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 10),

            // Theme Card
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Switch between light and dark theme',
                    style: TextStyle(fontSize: 11)),
                secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.primaryPurple),
                value: isDark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
              ),
            ),
            const SizedBox(height: 10),

            // Admin Console Card (only for admins)
            if (isAdmin)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                  title: const Text('Admin Console',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manage servers, plans & orders',
                      style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => context.push('/home/admin'),
                ),
              ),

            // Check Updates Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.system_update_rounded, color: AppTheme.accentAqua),
                title: const Text('Check for Updates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('OTA updates via GitHub Releases',
                    style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _checkUpdates(context),
              ),
            ),
            const SizedBox(height: 10),

            // About Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                    title: const Text('About RenCloud',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Version 1.5.1 • Minecraft Hosting Panel',
                        style: TextStyle(fontSize: 11)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: AppTheme.textSecondary),
                    title: const Text('Support',
                        style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text('Logout',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
