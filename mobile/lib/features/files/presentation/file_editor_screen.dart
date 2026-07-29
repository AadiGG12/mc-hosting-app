import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../servers/presentation/servers_provider.dart';

class FileEditorScreen extends ConsumerStatefulWidget {
  final String serverId;
  final String filePath;

  const FileEditorScreen({
    super.key,
    required this.serverId,
    required this.filePath,
  });

  @override
  ConsumerState<FileEditorScreen> createState() => _FileEditorScreenState();
}

class _FileEditorScreenState extends ConsumerState<FileEditorScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(serverRepoProvider);
      final content = await repo.getFileContents(widget.serverId, widget.filePath);
      _contentController.text = content;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(serverRepoProvider);
      final success = await repo.writeFileContents(
        widget.serverId,
        widget.filePath,
        _contentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'File saved successfully!' : 'Failed to save file'),
            backgroundColor: success ? AppTheme.primaryAccent : Colors.redAccent,
          ),
        );
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.filePath.split('/').last;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(filename, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              widget.filePath,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, color: AppTheme.primaryAccent),
            onPressed: _isSaving ? null : _saveFile,
          ),
        ],
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
                        onPressed: _loadFile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF030508),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                ),
    );
  }
}
