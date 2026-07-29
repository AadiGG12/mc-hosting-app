import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../plans/presentation/plans_screen.dart';
import '../../plans/data/cart_provider.dart';
import '../../servers/presentation/server_list_screen.dart';
import '../../profile/presentation/account_screen.dart';
import '../../admin/presentation/admin_screen.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context, isAdmin),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.storefront_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.storefront),
            ),
            label: 'Shop',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Servers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home/plans') || location.startsWith('/home/cart')) return 0;
    if (location.startsWith('/home/servers')) return 1;
    if (location.startsWith('/home/account')) return 2;
    if (location.startsWith('/home/admin')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isAdmin) {
    switch (index) {
      case 0:
        context.go('/home/plans');
        break;
      case 1:
        context.go('/home/servers');
        break;
      case 2:
        context.go('/home/account');
        break;
      case 3:
        if (isAdmin) {
          context.go('/home/admin');
        }
        break;
    }
  }
}
