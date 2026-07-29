import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> adminCategories = {
      'BASIC ADMINISTRATION': [
        {'title': 'Overview', 'subtitle': 'System health summary', 'icon': Icons.home_outlined, 'color': const Color(0xFF10B981), 'path': '/admin/nodes'},
        {'title': 'Statistics', 'subtitle': 'RAM, Disk & CPU usage', 'icon': Icons.query_stats, 'color': const Color(0xFF3B82F6), 'path': '/admin/nodes'},
        {'title': 'Settings', 'subtitle': 'Maintenance mode settings', 'icon': Icons.settings_outlined, 'color': const Color(0xFF8B5CF6), 'path': '/admin/nodes'},
        {'title': 'Application API', 'subtitle': 'Manage panel API keys', 'icon': Icons.vpn_key_outlined, 'color': const Color(0xFFEC4899), 'path': '/admin/nodes'},
        {'title': 'Audit Log', 'subtitle': 'Administrator audit trails', 'icon': Icons.receipt_long_outlined, 'color': const Color(0xFFF59E0B), 'path': '/admin/orders'},
        {'title': 'Panel Logs', 'subtitle': 'FastAPI & Ptero error logs', 'icon': Icons.assignment_outlined, 'color': const Color(0xFF06B6D4), 'path': '/admin/orders'},
      ],
      'MANAGEMENT': [
        {'title': 'Databases', 'subtitle': 'Global database hosts', 'icon': Icons.storage_outlined, 'color': const Color(0xFF10B981), 'path': '/admin/nodes'},
        {'title': 'Locations', 'subtitle': 'Geographical locations', 'icon': Icons.public_outlined, 'color': const Color(0xFF3B82F6), 'path': '/admin/nodes'},
        {'title': 'Nodes', 'subtitle': 'Node ports & IPs', 'icon': Icons.dns_outlined, 'color': const Color(0xFF8B5CF6), 'path': '/admin/nodes'},
        {'title': 'Servers', 'subtitle': 'All Pterodactyl servers', 'icon': Icons.list_alt_outlined, 'color': const Color(0xFFEC4899), 'path': '/admin/servers'},
        {'title': 'Users', 'subtitle': 'All 346+ panel user accounts', 'icon': Icons.people_outline, 'color': const Color(0xFFF59E0B), 'path': '/admin/users'},
      ],
      'SERVICE MANAGEMENT': [
        {'title': 'Mounts', 'subtitle': 'Shared storage mounts', 'icon': Icons.folder_shared_outlined, 'color': const Color(0xFF10B981), 'path': '/admin/nodes'},
        {'title': 'Nests', 'subtitle': 'Minecraft eggs & configurations', 'icon': Icons.egg_outlined, 'color': const Color(0xFF3B82F6), 'path': '/admin/nests'},
        {'title': 'Hosting Plans (CRUD)', 'subtitle': 'Configure plan pricing', 'icon': Icons.inventory_2_outlined, 'color': const Color(0xFF8B5CF6), 'path': '/admin/plans'},
        {'title': 'Orders & Revenue', 'subtitle': 'Revenue history & orders', 'icon': Icons.credit_card_outlined, 'color': const Color(0xFFEC4899), 'path': '/admin/orders'},
      ]
    };

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Root Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primaryAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pterodactyl Panel Administration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Full root administrative access to users, servers, nodes, nests, plans, and revenue.',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...adminCategories.entries.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
                    child: Text(
                      category.key,
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: category.value.length,
                    itemBuilder: (context, index) {
                      final module = category.value[index];
                      final color = module['color'] as Color;
                      return Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.push(module['path'] as String);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(module['icon'] as IconData, color: color, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        module['title'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  module['subtitle'] as String,
                                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
