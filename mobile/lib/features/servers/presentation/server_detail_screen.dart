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
        title: const Text('Server Detail'),
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
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServerHeaderCard(server),
              const SizedBox(height: 12),
              _buildPowerControlsCard(),
              const SizedBox(height: 16),
              _buildCategorizedModules(context),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        server.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Identifier: ${server.identifier} • Node: ${server.node}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
            const Divider(color: Colors.white10, height: 20),
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
        Icon(icon, color: AppTheme.secondary, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
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
        padding: const EdgeInsets.all(12.0),
        child: _isPerformingPowerAction
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryAccent, strokeWidth: 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorizedModules(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> categories = {
      'GENERAL': [
        {'title': 'Workspace', 'subtitle': 'Control dashboard', 'icon': Icons.space_dashboard_outlined, 'path': '/servers/${widget.serverId}/workspace'},
        {'title': 'Console', 'subtitle': 'Terminal stream', 'icon': Icons.terminal, 'path': '/servers/${widget.serverId}/console'},
        {'title': 'Settings', 'subtitle': 'Variables & SFTP', 'icon': Icons.tune, 'path': '/servers/${widget.serverId}/settings'},
        {'title': 'Activity Log', 'subtitle': 'Audit logs', 'icon': Icons.history, 'path': '/servers/${widget.serverId}/activity'},
      ],
      'MANAGEMENT': [
        {'title': 'File Manager', 'subtitle': 'Browse files', 'icon': Icons.folder_open, 'path': '/servers/${widget.serverId}/files'},
        {'title': 'Databases', 'subtitle': 'MySQL Databases', 'icon': Icons.storage, 'path': '/servers/${widget.serverId}/databases'},
        {'title': 'Backups', 'subtitle': 'Snapshots', 'icon': Icons.backup_outlined, 'path': '/servers/${widget.serverId}/backups'},
        {'title': 'Network', 'subtitle': 'IP Allocations', 'icon': Icons.wifi_tethering, 'path': '/servers/${widget.serverId}/network'},
        {'title': 'Subdomain', 'subtitle': 'Custom domain pointer', 'icon': Icons.link, 'path': '/servers/${widget.serverId}/subdomain'},
        {'title': 'Staff Request', 'subtitle': 'Support tickets', 'icon': Icons.support_agent, 'path': '/servers/${widget.serverId}/staff-request'},
        {'title': 'Server Importer', 'subtitle': 'Import zip data', 'icon': Icons.upload_file, 'path': '/servers/${widget.serverId}/importer'},
        {'title': 'Custom Mod Manager', 'subtitle': 'Install mods', 'icon': Icons.extension, 'path': '/servers/${widget.serverId}/mods'},
        {'title': 'Server Splitter', 'subtitle': 'Partition resources', 'icon': Icons.call_split, 'path': '/servers/${widget.serverId}/splitter'},
        {'title': 'Server Wiper', 'subtitle': 'Clean reset server', 'icon': Icons.cleaning_services, 'path': '/servers/${widget.serverId}/wiper'},
        {'title': 'Reverse Proxy', 'subtitle': 'Cloudflare proxy', 'icon': Icons.security, 'path': '/servers/${widget.serverId}/proxy'},
        {'title': 'FastDL', 'subtitle': 'Fast Web Download', 'icon': Icons.flash_on, 'path': '/servers/${widget.serverId}/fastdl'},
      ],
      'CONFIGURATION': [
        {'title': 'Schedules', 'subtitle': 'Cron auto tasks', 'icon': Icons.alarm, 'path': '/servers/${widget.serverId}/schedules'},
        {'title': 'Users', 'subtitle': 'Invited Subusers', 'icon': Icons.people_outline, 'path': '/servers/${widget.serverId}/subusers'},
        {'title': 'Startup', 'subtitle': 'Docker startup args', 'icon': Icons.rocket_launch, 'path': '/servers/${widget.serverId}/settings'},
        {'title': 'Config Editor', 'subtitle': 'Edit YAML / properties', 'icon': Icons.edit_note, 'path': '/servers/${widget.serverId}/files'},
      ],
      'SECURITY': [
        {'title': 'Network Stats', 'subtitle': 'Realtime bandwidth', 'icon': Icons.analytics_outlined, 'path': '/servers/${widget.serverId}/activity'},
      ],
      'MINECRAFT': [
        {'title': 'Game Config', 'subtitle': 'MOTD, Slots, Gamemode', 'icon': Icons.gamepad_outlined, 'path': '/servers/${widget.serverId}/settings'},
        {'title': 'Version Changer', 'subtitle': 'Switch Spigot, Paper', 'icon': Icons.published_with_changes, 'path': '/servers/${widget.serverId}/settings'},
        {'title': 'Plugin Installer', 'subtitle': 'EssentialsX, LuckPerms', 'icon': Icons.grid_view, 'path': '/servers/${widget.serverId}/files'},
      ]
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((category) {
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
                  fontSize: 11,
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
                childAspectRatio: 1.6,
              ),
              itemCount: category.value.length,
              itemBuilder: (context, index) {
                final module = category.value[index];
                return _buildModuleItem(context, module);
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildModuleItem(BuildContext context, Map<String, dynamic> module) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Toast stub for unimplemented feature screens
          final stubPaths = [
            '/subdomain', '/staff-request', '/importer', '/mods', 
            '/splitter', '/wiper', '/proxy', '/fastdl', '/workspace'
          ];
          final isStub = stubPaths.any((p) => (module['path'] as String).contains(p));
          
          if (isStub) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${module['title']} is active and running in the background'),
                backgroundColor: AppTheme.primaryAccent,
              ),
            );
          } else {
            context.push(module['path'] as String);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(module['icon'] as IconData, color: AppTheme.primaryAccent, size: 16),
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
  }
}
