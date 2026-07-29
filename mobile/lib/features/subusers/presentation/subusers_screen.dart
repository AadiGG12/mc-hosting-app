import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SubusersScreen extends StatefulWidget {
  final String serverId;
  const SubusersScreen({super.key, required this.serverId});

  @override
  State<SubusersScreen> createState() => _SubusersScreenState();
}

class _SubusersScreenState extends State<SubusersScreen> {
  List<Map<String, dynamic>> _subusers = [
    {
      'uuid': 'sub_1',
      'email': 'co_admin@rencloud.online',
      'username': 'CoAdminUser',
      'permissions': ['control.start', 'control.stop', 'control.restart', 'file.read', 'file.write'],
    }
  ];

  void _showAddSubuserDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Add Subuser'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Subuser Email Address',
            hintText: 'user@example.com',
            filled: true,
            fillColor: AppTheme.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (emailCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _subusers.add({
                    'uuid': 'sub_${DateTime.now().millisecondsSinceEpoch}',
                    'email': emailCtrl.text.trim(),
                    'username': emailCtrl.text.trim().split('@').first,
                    'permissions': ['control.start', 'control.restart', 'file.read'],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subuser invited successfully'), backgroundColor: AppTheme.primaryAccent),
                );
              }
            },
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Users & Access Control'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _subusers.isEmpty
          ? const Center(child: Text('No subusers added yet', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subusers.length,
              itemBuilder: (context, index) {
                final u = _subusers[index];
                final perms = (u['permissions'] as List).join(', ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.secondary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(u['email'] ?? u['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Permissions: $perms',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _subusers.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subuser removed')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubuserDialog,
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Subuser'),
      ),
    );
  }
}
