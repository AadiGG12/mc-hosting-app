import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../servers/data/server_models.dart';
import '../../servers/presentation/servers_provider.dart';

class ServerBackupsScreen extends ConsumerStatefulWidget {
  final String serverId;
  const ServerBackupsScreen({super.key, required this.serverId});

  @override
  ConsumerState<ServerBackupsScreen> createState() => _ServerBackupsScreenState();
}

class _ServerBackupsScreenState extends ConsumerState<ServerBackupsScreen> {
  List<ServerBackup> _backups = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(serverRepoProvider);
      final list = await repo.listBackups(widget.serverId);
      setState(() {
        _backups = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final repo = ref.read(serverRepoProvider);
      await repo.createBackup(widget.serverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup creation started!'),
            backgroundColor: AppTheme.primaryAccent,
          ),
        );
        _loadBackups();
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
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _deleteBackup(ServerBackup backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Backup?'),
        content: Text('Are you sure you want to delete backup "${backup.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(serverRepoProvider);
      final success = await repo.deleteBackup(widget.serverId, backup.uuid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Backup deleted' : 'Failed to delete backup'),
            backgroundColor: success ? AppTheme.primaryAccent : Colors.redAccent,
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Server Backups'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createBackup,
        backgroundColor: AppTheme.primaryAccent,
        icon: _isCreating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(_isCreating ? 'Creating...' : 'Create Backup'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text('Error: $_error', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadBackups,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _backups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.backup_outlined, size: 56, color: Colors.grey.shade700),
                          const SizedBox(height: 12),
                          const Text('No Backups Found', style: TextStyle(fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Create Backup" to save a snapshot of your server.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final b = _backups[index];
                        return Card(
                          color: AppTheme.cardBg,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.archive_outlined, color: AppTheme.secondary),
                            title: Text(b.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${_formatBytes(b.bytes)}${b.createdAt != null ? " • ${DateFormat('MMM dd, yyyy HH:mm').format(b.createdAt!)}" : ""}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteBackup(b),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
