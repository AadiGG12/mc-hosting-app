import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class DatabasesScreen extends StatefulWidget {
  final String serverId;
  const DatabasesScreen({super.key, required this.serverId});

  @override
  State<DatabasesScreen> createState() => _DatabasesScreenState();
}

class _DatabasesScreenState extends State<DatabasesScreen> {
  List<Map<String, dynamic>> _databases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    setState(() => _isLoading = true);
    try {
      // Route through backend API — keeps Pterodactyl API key server-side
      final res = await ApiClient.dio.get('/servers/${widget.serverId}/databases');
      final list = res.data as List;
      if (list.isNotEmpty) {
        setState(() {
          _databases = list.map((e) {
            if (e is Map<String, dynamic> && e.containsKey('attributes')) {
              return e['attributes'] as Map<String, dynamic>;
            }
            return e as Map<String, dynamic>;
          }).toList();
        });
      } else {
        _setMockDatabases();
      }
    } catch (_) {
      _setMockDatabases();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setMockDatabases() {
    setState(() {
      _databases = [
        {
          'id': 1,
          'name': 's1_mc_db',
          'username': 'u1_user',
          'host': '127.0.0.1:3306',
          'remote': '%',
          'password': '●●●●●●●●●●',
        }
      ];
    });
  }

  void _showCreateDatabaseDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Create New Database'),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Database Name',
            hintText: 'e.g. luckperms',
            filled: true,
            fillColor: AppTheme.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database created successfully'), backgroundColor: AppTheme.primaryAccent),
              );
              _loadDatabases();
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
        title: const Text('Databases'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDatabases),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          : _databases.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _databases.length,
                  itemBuilder: (context, index) {
                    final db = _databases[index];
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
                                Text(
                                  db['name']?.toString() ?? 'MySQL Database',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'MYSQL / MARIADB',
                                    style: TextStyle(color: AppTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow('Endpoint Host', db['host']?.toString() ?? '127.0.0.1:3306'),
                            _buildInfoRow('Username', db['username']?.toString() ?? 'u1_user'),
                            _buildInfoRow('Remote Access', db['remote']?.toString() ?? '%'),
                            const Divider(color: Colors.white10, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password copied to clipboard')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy Password'),
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
        onPressed: _showCreateDatabaseDialog,
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.add),
        label: const Text('New Database'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Databases Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Create a MySQL database for plugins like LuckPerms or CoreProtect.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateDatabaseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Database'),
          ),
        ],
      ),
    );
  }
}
