import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'servers_provider.dart';

class ServerDetailScreen extends ConsumerWidget {
  final String serverId;
  const ServerDetailScreen({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverAsync = ref.watch(serverProvider(serverId));
    return Scaffold(
      appBar: AppBar(title: const Text('Server Details')),
      body: serverAsync.when(
        data: (server) => Center(child: Text('Server: ${server.name}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      )
    );
  }
}
