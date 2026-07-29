import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../data/server_models.dart';
import 'servers_provider.dart';

enum ServerSortOption { node, name, ram, status }

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  ServerSortOption _sortOption = ServerSortOption.node;
  String _selectedNodeFilter = 'All Nodes';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(serversProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'My Servers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(serversProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(serversProvider),
        color: AppTheme.primaryAccent,
        child: serversAsync.when(
          data: (servers) {
            if (servers.isEmpty) return _buildEmptyState(context);

            // Extract unique node names for node filter chips
            final uniqueNodes = <String>{'All Nodes'};
            for (var s in servers) {
              uniqueNodes.add(s.node);
            }

            // Filter servers by Search text & Node filter
            final searchQuery = _searchCtrl.text.toLowerCase().trim();
            var filtered = servers.where((s) {
              final matchesSearch = searchQuery.isEmpty ||
                  s.name.toLowerCase().contains(searchQuery) ||
                  s.identifier.toLowerCase().contains(searchQuery) ||
                  s.node.toLowerCase().contains(searchQuery);

              final matchesNode = _selectedNodeFilter == 'All Nodes' || s.node == _selectedNodeFilter;

              return matchesSearch && matchesNode;
            }).toList();

            // Sort servers according to selected option
            if (_sortOption == ServerSortOption.node) {
              filtered.sort((a, b) => a.node.compareTo(b.node));
            } else if (_sortOption == ServerSortOption.name) {
              filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            } else if (_sortOption == ServerSortOption.ram) {
              filtered.sort((a, b) => b.memory.compareTo(a.memory));
            } else if (_sortOption == ServerSortOption.status) {
              filtered.sort((a, b) => a.status.index.compareTo(b.status.index));
            }

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search servers by name, ID, or node...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.secondary),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Sort & Node Filter Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // Sort Dropdown Button
                      PopupMenuButton<ServerSortOption>(
                        initialValue: _sortOption,
                        onSelected: (opt) {
                          setState(() {
                            _sortOption = opt;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sort, size: 16, color: AppTheme.primaryAccent),
                              const SizedBox(width: 6),
                              Text(
                                'Sort: ${_sortOption.name.toUpperCase()}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: ServerSortOption.node,
                            child: Text('Sort by Node'),
                          ),
                          PopupMenuItem(
                            value: ServerSortOption.name,
                            child: Text('Sort by Name'),
                          ),
                          PopupMenuItem(
                            value: ServerSortOption.ram,
                            child: Text('Sort by RAM'),
                          ),
                          PopupMenuItem(
                            value: ServerSortOption.status,
                            child: Text('Sort by Status'),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Node Filter Chips
                      ...uniqueNodes.map((nodeName) {
                        final isSelected = _selectedNodeFilter == nodeName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              nodeName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selectedColor: AppTheme.primaryAccent,
                            backgroundColor: AppTheme.surface,
                            onSelected: (selected) {
                              setState(() {
                                _selectedNodeFilter = nodeName;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Server List Body
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No servers match your search or filter',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final s = filtered[index];

                            // If sorting by node, show node header when node changes
                            bool showNodeHeader = false;
                            if (_sortOption == ServerSortOption.node) {
                              if (index == 0 || filtered[index - 1].node != s.node) {
                                showNodeHeader = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showNodeHeader) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.dns, size: 16, color: AppTheme.secondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          s.node.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.secondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                _buildServerCard(context, s),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryAccent),
          ),
          error: (e, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  'Failed to load servers: ${e.toString()}',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(serversProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dns_outlined, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            'No Minecraft Servers Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Purchase a hosting plan to automatically provision your server.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go('/home/plans'),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Browse Plans'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, Server s) {
    final isOnline = s.status == ServerStatus.running;
    final isOffline = s.status == ServerStatus.offline;
    final isSuspended = s.status == ServerStatus.suspended;

    final statusColor = isOnline
        ? AppTheme.primaryAccent
        : isOffline
            ? Colors.grey
            : isSuspended
                ? Colors.orange
                : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/servers/${s.identifier}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.status.name.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.dns_outlined, size: 14, color: AppTheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    s.node,
                    style: const TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    ' • ID: ${s.identifier}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.memory, '${s.memory} MB', 'RAM'),
                  _buildStatItem(Icons.storage, '${(s.disk / 1024).toStringAsFixed(1)} GB', 'Disk'),
                  _buildStatItem(Icons.speed, '${s.cpu}%', 'CPU Limit'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.secondary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}
