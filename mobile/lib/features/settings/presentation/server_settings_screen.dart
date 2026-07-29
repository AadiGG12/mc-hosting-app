import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../servers/presentation/servers_provider.dart';

class ServerSettingsScreen extends ConsumerWidget {
  final String serverId;
  const ServerSettingsScreen({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverAsync = ref.watch(serverProvider(serverId));

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Server Settings'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: serverAsync.when(
        data: (server) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('RESOURCE ALLOCATION'),
              const SizedBox(height: 8),
              _buildInfoTile('RAM Memory Limit', '${server.memory} MB', Icons.memory),
              _buildInfoTile('Disk Storage Space', '${(server.disk / 1024).toStringAsFixed(1)} GB', Icons.storage),
              _buildInfoTile('CPU Execution Limit', '${server.cpu}%', Icons.speed),
              const SizedBox(height: 24),
              _buildSectionHeader('STARTUP CONFIGURATION'),
              const SizedBox(height: 8),
              _buildInfoTile('Node Location', server.node, Icons.dns),
              _buildInfoTile('Server UUID', server.uuid.isNotEmpty ? server.uuid : server.identifier, Icons.fingerprint),
              _buildInfoTile('Docker Image', 'ghcr.io/pterodactyl/yolks:java_21', Icons.layers),
              _buildInfoTile('Startup Command', 'java -Xms128M -XX:MaxRAMPercentage=95.0 -jar {{SERVER_JARFILE}}', Icons.terminal),
              const SizedBox(height: 24),
              _buildSectionHeader('ENVIRONMENT VARIABLES'),
              const SizedBox(height: 8),
              _buildInfoTile('SERVER_JARFILE', 'server.jar', Icons.code),
              _buildInfoTile('MINECRAFT_VERSION', 'latest', Icons.videogame_asset),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
        error: (e, st) => Center(child: Text(e.toString(), style: const TextStyle(color: Colors.grey))),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Card(
      color: AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.secondary, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
