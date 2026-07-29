import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SchedulesScreen extends StatefulWidget {
  final String serverId;
  const SchedulesScreen({super.key, required this.serverId});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  List<Map<String, dynamic>> _schedules = [
    {
      'id': 1,
      'name': 'Daily Server Restart & Backup',
      'cron': '0 4 * * *',
      'is_active': true,
      'last_run': '2026-07-29 04:00:00',
      'next_run': '2026-07-30 04:00:00',
      'tasks_count': 2,
    },
    {
      'id': 2,
      'name': 'Hourly World Save (/save-all)',
      'cron': '0 * * * *',
      'is_active': true,
      'last_run': '2026-07-29 16:00:00',
      'next_run': '2026-07-29 17:00:00',
      'tasks_count': 1,
    },
  ];

  void _showCreateScheduleDialog() {
    final nameCtrl = TextEditingController();
    final cronCtrl = TextEditingController(text: '0 0 * * *');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Create New Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Schedule Name',
                hintText: 'e.g. Daily Restart',
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cronCtrl,
              decoration: InputDecoration(
                labelText: 'Cron Expression (Minute Hour Day Month DayOfWeek)',
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _schedules.add({
                    'id': _schedules.length + 1,
                    'name': nameCtrl.text.trim(),
                    'cron': cronCtrl.text.trim(),
                    'is_active': true,
                    'last_run': 'Never',
                    'next_run': 'Scheduled',
                    'tasks_count': 1,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Schedule created successfully'), backgroundColor: AppTheme.primaryAccent),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Schedules & Cron Tasks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _schedules.isEmpty
          ? const Center(child: Text('No schedules created', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final s = _schedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                s['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s['is_active'] ? AppTheme.primaryAccent.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s['is_active'] ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  color: s['is_active'] ? AppTheme.primaryAccent : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cron: ${s['cron']} • Tasks: ${s['tasks_count']}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Next Run: ${s['next_run']}',
                          style: const TextStyle(color: AppTheme.secondary, fontSize: 12),
                        ),
                        const Divider(color: Colors.white10, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Triggered "${s['name']}" now'), backgroundColor: AppTheme.primaryAccent),
                                );
                              },
                              icon: const Icon(Icons.play_arrow, size: 16, color: AppTheme.primaryAccent),
                              label: const Text('Run Now', style: TextStyle(color: AppTheme.primaryAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateScheduleDialog,
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.add_alarm),
        label: const Text('New Schedule'),
      ),
    );
  }
}
