import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'servers_provider.dart';

class ServerListScreen extends ConsumerWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serversProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Servers')),
      body: serversAsync.when(
        data: (servers) => servers.isEmpty 
          ? const Center(child: Text('No servers yet'))
          : ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final s = servers[index];
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.identifier),
                  onTap: () => context.push('/servers/${s.identifier}'),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}
