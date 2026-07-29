import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminModules = [
      {
        'title': 'User Management',
        'subtitle': 'Manage 346+ Pterodactyl users & roles',
        'icon': Icons.people_alt_outlined,
        'color': const Color(0xFF10B981),
        'path': '/admin/users',
      },
      {
        'title': 'Server Management',
        'subtitle': 'View, suspend, or delete panel servers',
        'icon': Icons.dns_outlined,
        'color': const Color(0xFF3B82F6),
        'path': '/admin/servers',
      },
      {
        'title': 'Nodes & Infrastructure',
        'subtitle': 'Node FQDNs, locations & RAM limits',
        'icon': Icons.router_outlined,
        'color': const Color(0xFF8B5CF6),
        'path': '/admin/nodes',
      },
      {
        'title': 'Nests & Eggs',
        'subtitle': 'Minecraft Java, Bedrock, Spigot, Paper',
        'icon': Icons.egg_outlined,
        'color': const Color(0xFFEC4899),
        'path': '/admin/nests',
      },
      {
        'title': 'Hosting Plans (CRUD)',
        'subtitle': 'Configure RAM/CPU pricing tiers',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFFF59E0B),
        'path': '/admin/plans',
      },
      {
        'title': 'Orders & Revenue',
        'subtitle': 'Customer order history & payments',
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFF06B6D4),
        'path': '/admin/orders',
      },
    ];

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primaryAccent, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pterodactyl Panel Administration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Full root administrative access to users, servers, nodes, nests, plans, and revenue.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ADMINISTRATIVE CONTROL MODULES',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: adminModules.length,
              itemBuilder: (context, index) {
                final mod = adminModules[index];
                final color = mod['color'] as Color;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push(mod['path'] as String),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(mod['icon'] as IconData, color: color, size: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mod['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mod['subtitle'] as String,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 2,
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
        ),
      ),
    );
  }
}
