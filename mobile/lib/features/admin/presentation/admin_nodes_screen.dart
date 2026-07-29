import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

class AdminNodesScreen extends StatefulWidget {
  const AdminNodesScreen({super.key});

  @override
  State<AdminNodesScreen> createState() => _AdminNodesScreenState();
}

class _AdminNodesScreenState extends State<AdminNodesScreen> {
  final AdminRepository _repo = AdminRepository();
  List<AdminNode> _nodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    setState(() => _isLoading = true);
    final nodes = await _repo.getNodes();
    setState(() {
      _nodes = nodes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('Nodes & Infrastructure (${_nodes.length})'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNodes),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          : _nodes.isEmpty
              ? const Center(child: Text('No nodes configured', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nodes.length,
                  itemBuilder: (context, index) {
                    final n = _nodes[index];
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
                                  n.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ONLINE',
                                    style: TextStyle(color: AppTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'FQDN: ${n.fqdn} • Location ID: ${n.locationId}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                            const Divider(color: Colors.white10, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text('${n.memory} MB', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Text('Total RAM', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('${(n.disk / 1024).toStringAsFixed(1)} GB', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Text('Total Disk', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
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
