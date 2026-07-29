import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class NetworkScreen extends StatefulWidget {
  final String serverId;
  const NetworkScreen({super.key, required this.serverId});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  List<Map<String, dynamic>> _allocations = [
    {
      'id': 101,
      'ip': 'node1.rencloud.online',
      'port': 25565,
      'is_primary': true,
      'notes': 'Default Minecraft Port',
    },
    {
      'id': 102,
      'ip': 'node1.rencloud.online',
      'port': 8123,
      'is_primary': false,
      'notes': 'Dynmap Web Port',
    },
    {
      'id': 103,
      'ip': 'node1.rencloud.online',
      'port': 24454,
      'is_primary': false,
      'notes': 'Simple Voice Chat UDP Port',
    },
  ];

  void _setPrimary(int id) {
    setState(() {
      for (var a in _allocations) {
        a['is_primary'] = a['id'] == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Primary allocation updated'), backgroundColor: AppTheme.primaryAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Network & Allocations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allocations.length,
        itemBuilder: (context, index) {
          final alloc = _allocations[index];
          final isPrimary = alloc['is_primary'] == true;
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
                      SelectableText(
                        '${alloc["ip"]}:${alloc["port"]}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(color: AppTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Notes: ${alloc["notes"]}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied ${alloc["ip"]}:${alloc["port"]} to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy IP:Port'),
                      ),
                      if (!isPrimary) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _setPrimary(alloc['id']),
                          child: const Text('Make Primary', style: TextStyle(color: AppTheme.secondary)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
