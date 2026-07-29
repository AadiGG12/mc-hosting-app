import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../servers/data/server_models.dart';
import '../../servers/presentation/servers_provider.dart';

class FileManagerScreen extends ConsumerStatefulWidget {
  final String serverId;
  const FileManagerScreen({super.key, required this.serverId});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  String _currentDir = '/';
  List<ServerFile> _files = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentDir);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(serverRepoProvider);
      final list = await repo.listFiles(widget.serverId, path);
      setState(() {
        _currentDir = path;
        _files = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(ServerFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete "${file.name}"? This action cannot be undone.'),
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
      final success = await repo.deleteFile(widget.serverId, _currentDir, [file.name]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Deleted "${file.name}"' : 'Failed to delete file'),
            backgroundColor: success ? AppTheme.primaryAccent : Colors.redAccent,
          ),
        );
        _loadDirectory(_currentDir);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _navigateUp() {
    if (_currentDir == '/' || _currentDir.isEmpty) return;
    final parts = _currentDir.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) parts.removeLast();
    final parentDir = parts.isEmpty ? '/' : '/${parts.join('/')}';
    _loadDirectory(parentDir);
  }

  IconData _getFileIcon(ServerFile file) {
    if (!file.isFile) return Icons.folder;
    final ext = file.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'yml':
      case 'yaml':
      case 'json':
      case 'properties':
      case 'conf':
        return Icons.code;
      case 'jar':
        return Icons.layers;
      case 'txt':
      case 'log':
        return Icons.description;
      case 'png':
      case 'jpg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(ServerFile file) {
    if (!file.isFile) return const Color(0xFFF59E0B);
    final ext = file.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'yml':
      case 'yaml':
      case 'json':
      case 'properties':
        return const Color(0xFF3B82F6);
      case 'jar':
        return const Color(0xFF10B981);
      case 'log':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              _currentDir,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDirectory(_currentDir),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentDir != '/')
            Container(
              color: AppTheme.cardBg,
              child: ListTile(
                leading: const Icon(Icons.arrow_upward, color: AppTheme.secondary),
                title: const Text('.. (Parent Directory)', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: _navigateUp,
              ),
            ),
          Expanded(
            child: _isLoading
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
                              onPressed: () => _loadDirectory(_currentDir),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _files.isEmpty
                        ? const Center(child: Text('Empty folder', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: _files.length,
                            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return ListTile(
                                leading: Icon(_getFileIcon(file), color: _getFileIconColor(file)),
                                title: Text(
                                  file.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  file.isFile
                                      ? '${_formatBytes(file.size)}${file.modifiedAt != null ? " • ${DateFormat('MMM dd, HH:mm').format(file.modifiedAt!)}" : ""}'
                                      : 'Directory',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteFile(file),
                                ),
                                onTap: () {
                                  if (!file.isFile) {
                                    final newPath = _currentDir == '/' ? '/${file.name}' : '$_currentDir/${file.name}';
                                    _loadDirectory(newPath);
                                  } else {
                                    final filePath = _currentDir == '/' ? file.name : '$_currentDir/${file.name}';
                                    context.push('/servers/${widget.serverId}/files/editor?path=${Uri.encodeComponent(filePath)}');
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
