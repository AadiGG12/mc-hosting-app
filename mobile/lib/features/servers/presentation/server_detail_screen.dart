import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../data/server_models.dart';
import 'servers_provider.dart';

class ServerDetailScreen extends ConsumerStatefulWidget {
  final String serverId;
  const ServerDetailScreen({super.key, required this.serverId});

  @override
  ConsumerState<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen> {
  bool _isPerformingPowerAction = false;

  Future<void> _handlePowerAction(String signal) async {
    setState(() {
      _isPerformingPowerAction = true;
    });

    try {
      final repo = ref.read(serverRepoProvider);
      final success = await repo.sendPowerSignal(widget.serverId, signal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Signal "$signal" sent successfully' : 'Failed to send signal "$signal"',
            ),
            backgroundColor: success ? AppTheme.primaryAccent : Colors.redAccent,
          ),
        );
        ref.refresh(serverProvider(widget.serverId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingPowerAction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverAsync = ref.watch(serverProvider(widget.serverId));

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Server Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(serverProvider(widget.serverId)),
          ),
        ],
      ),
      body: serverAsync.when(
        data: (server) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServerHeaderCard(server),
              const SizedBox(height: 20),
              const Text(
                'POWER CONTROLS',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              _buildPowerControlsCard(),
              const SizedBox(height: 24),
              const Text(
                'MANAGEMENT MODULES',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              _buildManagementGrid(context),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Error: ${e.toString()}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(serverProvider(widget.serverId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerHeaderCard(Server server) {
    final isOnline = server.status == ServerStatus.running;
    final statusColor = isOnline ? AppTheme.primaryAccent : Colors.redAccent;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    server.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        server.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Identifier: ${server.identifier} • Node: ${server.node}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const Divider(color: Colors.white10, height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('RAM', '${server.memory} MB', Icons.memory),
                _buildMetricColumn('Disk', '${(server.disk / 1024).toStringAsFixed(1)} GB', Icons.storage),
                _buildMetricColumn('CPU Limit', '${server.cpu}%', Icons.speed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPowerControlsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPerformingPowerAction
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPowerButton('Start', Icons.play_arrow, Colors.green, () => _handlePowerAction('start')),
                  _buildPowerButton('Restart', Icons.refresh, Colors.orange, () => _handlePowerAction('restart')),
                  _buildPowerButton('Stop', Icons.stop, Colors.redAccent, () => _handlePowerAction('stop')),
                  _buildPowerButton('Kill', Icons.power_settings_new, Colors.purple, () => _handlePowerAction('kill')),
                ],
              ),
      ),
    );
  }

  Widget _buildPowerButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    final modules = [
      {
        'title': 'Console',
        'subtitle': 'Realtime Terminal & Logs',
        'icon': Icons.terminal,
        'color': const Color(0xFF10B981),
        'path': '/servers/${widget.serverId}/console',
      },
      {
        'title': 'File Manager',
        'subtitle': 'Browse & Edit Files',
        'icon': Icons.folder_open,
        'color': const Color(0xFF3B82F6),
        'path': '/servers/${widget.serverId}/files',
      },
      {
        'title': 'Databases',
        'subtitle': 'MySQL / MariaDB Instances',
        'icon': Icons.storage,
        'color': const Color(0xFF8B5CF6),
        'path': '/servers/${widget.serverId}/databases',
      },
      {
        'title': 'Schedules',
        'subtitle': 'Cron Jobs & Automation',
        'icon': Icons.alarm,
        'color': const Color(0xFFEC4899),
        'path': '/servers/${widget.serverId}/schedules',
      },
      {
        'title': 'Users & Access',
        'subtitle': 'Subusers & Permissions',
        'icon': Icons.people_outline,
        'color': const Color(0xFF14B8A6),
        'path': '/servers/${widget.serverId}/subusers',
      },
      {
        'title': 'Backups',
        'subtitle': 'Snapshots & Restores',
        'icon': Icons.backup,
        'color': const Color(0xFFF59E0B),
        'path': '/servers/${widget.serverId}/backups',
      },
      {
        'title': 'Network & Ports',
        'subtitle': 'IP Allocations & Ports',
        'icon': Icons.wifi_tethering,
        'color': const Color(0xFF06B6D4),
        'path': '/servers/${widget.serverId}/network',
      },
      {
        'title': 'Settings & SFTP',
        'subtitle': 'Startup Command & SFTP',
        'icon': Icons.tune,
        'color': const Color(0xFF6366F1),
        'path': '/servers/${widget.serverId}/settings',
      },
      {
        'title': 'Activity Logs',
        'subtitle': 'Audit Trail of Actions',
        'icon': Icons.history,
        'color': const Color(0xFF64748B),
        'path': '/servers/${widget.serverId}/activity',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final mod = modules[index];
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mod['subtitle'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
