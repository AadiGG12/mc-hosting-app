import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

class AdminServersScreen extends StatefulWidget {
  const AdminServersScreen({super.key});

  @override
  State<AdminServersScreen> createState() => _AdminServersScreenState();
}

class _AdminServersScreenState extends State<AdminServersScreen> {
  final AdminRepository _repo = AdminRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<AdminServer> _servers = [];
  List<AdminServer> _filteredServers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
    _searchCtrl.addListener(_filterServers);
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);
    final servers = await _repo.getServers();
    setState(() {
      _servers = servers;
      _filteredServers = servers;
      _isLoading = false;
    });
  }

  void _filterServers() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredServers = _servers;
      } else {
        _filteredServers = _servers.where((s) {
          return s.name.toLowerCase().contains(query) ||
              s.identifier.toLowerCase().contains(query) ||
              s.id.toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _toggleSuspend(AdminServer s) async {
    final success = s.isSuspended
        ? await _repo.unsuspendServer(s.id)
        : await _repo.suspendServer(s.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Server "${s.name}" ${s.isSuspended ? "unsuspended" : "suspended"}'
                : 'Action failed',
          ),
          backgroundColor: success ? AppTheme.primaryAccent : Colors.redAccent,
        ),
      );
      _loadServers();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('All Pterodactyl Servers (${_servers.length})'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadServers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search servers by name or identifier...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.secondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                : _filteredServers.isEmpty
                    ? const Center(child: Text('No servers found', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredServers.length,
                        itemBuilder: (context, index) {
                          final s = _filteredServers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: s.isSuspended ? Colors.redAccent.withOpacity(0.2) : AppTheme.primaryAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          s.isSuspended ? 'SUSPENDED' : 'ACTIVE',
                                          style: TextStyle(
                                            color: s.isSuspended ? Colors.redAccent : AppTheme.primaryAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ID: ${s.id} • UUID: ${s.identifier} • Node: ${s.nodeId} • Owner ID: ${s.ownerId}',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Specs: ${s.memory} MB RAM / ${(s.disk / 1024).toStringAsFixed(1)} GB Disk',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _toggleSuspend(s),
                                        icon: Icon(
                                          s.isSuspended ? Icons.play_arrow : Icons.pause,
                                          size: 16,
                                          color: s.isSuspended ? AppTheme.primaryAccent : Colors.orangeAccent,
                                        ),
                                        label: Text(
                                          s.isSuspended ? 'Unsuspend' : 'Suspend',
                                          style: TextStyle(
                                            color: s.isSuspended ? AppTheme.primaryAccent : Colors.orangeAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
