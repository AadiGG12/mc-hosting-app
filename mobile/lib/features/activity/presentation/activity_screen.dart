import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ActivityScreen extends StatefulWidget {
  final String serverId;
  const ActivityScreen({super.key, required this.serverId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<Map<String, dynamic>> _logs = [
    {
      'action': 'server:power.start',
      'description': 'Issued START power signal',
      'user': 'Owner',
      'time': '5 mins ago',
      'icon': Icons.play_arrow,
      'color': Colors.green,
    },
    {
      'action': 'file:write',
      'description': 'Saved file "server.properties"',
      'user': 'Owner',
      'time': '1 hour ago',
      'icon': Icons.edit_note,
      'color': Colors.blue,
    },
    {
      'action': 'backup:create',
      'description': 'Created automated backup "Auto Backup #1"',
      'user': 'System Cron',
      'time': '12 hours ago',
      'icon': Icons.backup,
      'color': Colors.orange,
    },
    {
      'action': 'database:create',
      'description': 'Created MySQL Database "s1_mc_db"',
      'user': 'Owner',
      'time': '1 day ago',
      'icon': Icons.storage,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Activity Audit Logs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          final color = log['color'] as Color;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(log['icon'] as IconData, color: color, size: 20),
              ),
              title: Text(log['description'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                'By ${log["user"]} • ${log["time"]}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log['action'] as String,
                  style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
