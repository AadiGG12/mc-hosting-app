import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/theme.dart';
import '../../servers/presentation/servers_provider.dart';

class ConsoleScreen extends ConsumerStatefulWidget {
  final String serverId;
  const ConsoleScreen({super.key, required this.serverId});

  @override
  ConsumerState<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends ConsumerState<ConsoleScreen> {
  final List<String> _logs = [];
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  bool _isConnected = false;
  bool _isConnecting = true;
  String _statusMessage = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Fetching WebSocket credentials...';
    });

    try {
      final repo = ref.read(serverRepoProvider);
      final wsCreds = await repo.getWebsocketCredentials(widget.serverId);

      String socketUrl = wsCreds['socket'] ?? '';
      final token = wsCreds['token'] ?? '';

      if (socketUrl.isEmpty) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'No WebSocket URL';
        });
        _appendLog('[SYSTEM] ⚠ Could not retrieve WebSocket endpoint from panel.');
        _appendLog('[SYSTEM] The node may be offline or unreachable.');
        return;
      }

      // Fix URL scheme: ensure wss:// (not https://)
      if (socketUrl.startsWith('https://')) {
        socketUrl = 'wss://' + socketUrl.substring(8);
      } else if (socketUrl.startsWith('http://')) {
        socketUrl = 'ws://' + socketUrl.substring(7);
      }

      // Remove port :0 which causes invalid WebSocket connection
      socketUrl = socketUrl.replaceAll(':0/', '/').replaceAll(':0#', '#').replaceAll(':0', '');

      // Strip URL fragment (#...) — breaks WebSocket upgrade
      if (socketUrl.contains('#')) {
        socketUrl = socketUrl.split('#')[0];
      }

      if (token.isEmpty) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Auth failed — node may be offline';
        });
        _appendLog('[SYSTEM] ⚠ WebSocket token is empty. Session login may have failed.');
        _appendLog('[SYSTEM] Node might be offline or not accepting connections.');
        _appendLog('[SYSTEM] Try refreshing or check the panel: https://panel.rencloud.online');
        return;
      }

      final uri = Uri.parse(socketUrl);
      _channel = WebSocketChannel.connect(uri);

      // Authenticate with WebSocket token frame
      _channel!.sink.add(jsonEncode({
        'event': 'auth',
        'args': [token]
      }));

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _statusMessage = 'Connected';
      });

      _appendLog('[SYSTEM] ✓ Connected to console stream.');

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            final event = data['event'];
            final args = data['args'] as List?;

            if (event == 'console output' && args != null && args.isNotEmpty) {
              for (final line in args) {
                _appendLog(line.toString());
              }
            } else if (event == 'status' && args != null && args.isNotEmpty) {
              _appendLog('[STATUS] Server state: ${args[0]}');
            } else if (event == 'token expiring') {
              _appendLog('[SYSTEM] Token expiring, refreshing...');
              _refreshToken(token);
            } else if (event == 'jwt error') {
              setState(() {
                _isConnected = false;
                _statusMessage = 'Auth error';
              });
              _appendLog('[SYSTEM] ⚠ Authentication rejected by panel. Token may be invalid.');
            }
          } catch (_) {
            _appendLog(message.toString());
          }
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _statusMessage = 'Node unreachable';
          });
          // Friendly message instead of raw WebSocketChannelException
          _appendLog('[SYSTEM] ⚠ Connection lost. The node may be offline or the server is not running.');
          _appendLog('[SYSTEM] Start the server from the power controls to reconnect.');
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _statusMessage = 'Disconnected';
          });
          _appendLog('[SYSTEM] Console stream disconnected.');
        },
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Node offline';
      });
      // Never show raw WebSocketChannelException to user
      _appendLog('[SYSTEM] ⚠ Could not connect to the server console.');
      _appendLog('[SYSTEM] The node hosting this server may be temporarily offline.');
      _appendLog('[SYSTEM] Try again later or check status at https://panel.rencloud.online');
    }
  }


  Future<void> _refreshToken(String oldToken) async {
    try {
      final repo = ref.read(serverRepoProvider);
      final wsCreds = await repo.getWebsocketCredentials(widget.serverId);
      final newToken = wsCreds['token'];
      if (newToken != null && _channel != null) {
        _channel!.sink.add(jsonEncode({
          'event': 'auth',
          'args': [newToken]
        }));
      }
    } catch (_) {}
  }

  void _appendLog(String text) {
    // Strip ANSI escape codes for clean terminal display
    final cleanText = text.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
    setState(() {
      _logs.add(cleanText);
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendCommand() {
    final cmd = _cmdController.text.trim();
    if (cmd.isEmpty) return;

    _cmdController.clear();
    _appendLog('> $cmd');

    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'event': 'send command',
        'args': [cmd]
      }));
    } else {
      _appendLog('[SYSTEM WARNING] Command not sent: console disconnected.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _cmdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Console', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'Server ${widget.serverId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _subscription?.cancel();
              _channel?.sink.close();
              _connectWebSocket();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF030508),
              padding: const EdgeInsets.all(12),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        _isConnecting ? 'Connecting to server terminal...' : 'No logs output yet',
                        style: TextStyle(color: Colors.grey.shade600, fontFamily: 'monospace'),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isCommand = log.startsWith('>');
                        final isError = log.contains('[ERROR]') || log.contains('Exception') || log.contains('WARN');
                        
                        Color textColor = Colors.grey.shade300;
                        if (isCommand) textColor = Colors.cyanAccent;
                        if (isError) textColor = Colors.amberAccent;

                        return SelectableText(
                          log,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        );
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cmdController,
                    onSubmitted: (_) => _sendCommand(),
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter server command...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF141824),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primaryAccent),
                  onPressed: _sendCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
