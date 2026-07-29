import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedAdminTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Admin Console',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildTab(0, 'Plans', Icons.inventory_2_outlined),
                _buildTab(1, 'Servers', Icons.dns_outlined),
                _buildTab(2, 'Orders', Icons.receipt_outlined),
                _buildTab(3, 'Overview', Icons.dashboard_outlined),
              ],
            ),
          ),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedAdminTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAdminTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedAdminTab) {
      case 0:
        return _buildPlansManagement();
      case 1:
        return _buildServerManagement();
      case 2:
        return _buildOrdersManagement();
      case 3:
        return _buildOverview();
      default:
        return _buildPlansManagement();
    }
  }

  Widget _buildPlansManagement() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hosting Plans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => context.push('/admin/plans/create'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAqua,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Plan Stats
          Row(
            children: [
              _buildStatCard('Total Plans', '6', Icons.inventory_2, const Color(0xFF7C3AED)),
              _buildStatCard('Active', '4', Icons.check_circle, const Color(0xFF10B981)),
              _buildStatCard('Featured', '2', Icons.auto_awesome, const Color(0xFF06B6D4)),
            ],
          ),
          const SizedBox(height: 16),

          // Realtime Plan List
          Card(
            child: Column(
              children: [
                _buildPlanListItem('Dirt', '₹99/mo', '2GB RAM', true, true, isDark),
                const Divider(height: 1),
                _buildPlanListItem('Iron', '₹249/mo', '4GB RAM', true, false, isDark),
                const Divider(height: 1),
                _buildPlanListItem('Gold', '₹499/mo', '6GB RAM', true, true, isDark),
                const Divider(height: 1),
                _buildPlanListItem('Diamond', '₹999/mo', '8GB RAM', true, false, isDark),
                const Divider(height: 1),
                _buildPlanListItem('Emerald', '₹1,999/mo', '16GB RAM', false, false, isDark),
                const Divider(height: 1),
                _buildPlanListItem('Netherite', '₹3,999/mo', '32GB RAM', false, false, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanListItem(
      String name, String price, String ram, bool isActive, bool isFeatured, bool isDark) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Editing $name plan...'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud, color: AppTheme.primaryPurple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppTheme.textPrimaryLight)),
                      if (isFeatured)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('POPULAR',
                              style:
                                  TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text('$ram • $price',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: isActive,
              activeColor: AppTheme.accentAqua,
              onChanged: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${val ? "Activated" : "Deactivated"} $name'),
                    backgroundColor: AppTheme.accentAqua,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All Servers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildServerListItem('MC Survival', 'Node-1', 'Running', Colors.green),
                const Divider(height: 1),
                _buildServerListItem('Skyblock', 'Node-2', 'Offline', Colors.grey),
                const Divider(height: 1),
                _buildServerListItem('Creative', 'Node-1', 'Running', Colors.green),
                const Divider(height: 1),
                _buildServerListItem('PvP Arena', 'Node-3', 'Suspended', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerListItem(String name, String node, String status, Color statusColor) {
    return InkWell(
      onTap: () => context.push('/admin/servers'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentAqua.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dns, color: AppTheme.accentAqua, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Node: $node',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => context.push('/admin/orders'),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildOrderItem('#ORD-001', 'Gold Plan', '₹499', 'Paid', Colors.green),
                const Divider(height: 1),
                _buildOrderItem('#ORD-002', 'Iron Plan', '₹249', 'Provisioning', Colors.orange),
                const Divider(height: 1),
                _buildOrderItem('#ORD-003', 'Diamond Plan', '₹999', 'Failed', Colors.red),
                const Divider(height: 1),
                _buildOrderItem('#ORD-004', 'Dirt Plan', '₹99', 'Active', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
      String orderId, String plan, String amount, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: AppTheme.primaryPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$orderId • $plan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Amount: $amount',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildOverviewCard('Total Servers', '24', Icons.dns, const Color(0xFF7C3AED), 'Across 3 nodes'),
              _buildOverviewCard('Active Users', '346', Icons.people, const Color(0xFF06B6D4), '+12 this week'),
              _buildOverviewCard('Monthly Revenue', '₹12,450', Icons.currency_rupee, const Color(0xFF10B981), '+8% growth'),
              _buildOverviewCard('Pending Orders', '2', Icons.pending_actions, const Color(0xFFF59E0B), 'Need attention'),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickAction(Icons.add_circle_outline, 'Create New Plan',
                      () => context.push('/admin/plans/create')),
                  const Divider(height: 1),
                  _buildQuickAction(Icons.people_outline, 'Manage Users',
                      () => context.push('/admin/users')),
                  const Divider(height: 1),
                  _buildQuickAction(Icons.dns_outlined, 'View All Servers',
                      () => context.push('/admin/servers')),
                  const Divider(height: 1),
                  _buildQuickAction(Icons.receipt_long_outlined, 'View Orders',
                      () => context.push('/admin/orders')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.only(right: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              Text(title,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 16),
              ],
            ),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(title,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            Text(subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryPurple),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
      dense: true,
    );
  }
}
