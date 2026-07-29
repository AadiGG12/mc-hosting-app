import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/plans/presentation/plans_screen.dart';
import '../features/plans/presentation/plan_detail_screen.dart';
import '../features/servers/presentation/server_list_screen.dart';
import '../features/servers/presentation/server_detail_screen.dart';
import '../features/console/presentation/console_screen.dart';
import '../features/files/presentation/file_manager_screen.dart';
import '../features/files/presentation/file_editor_screen.dart';
import '../features/databases/presentation/databases_screen.dart';
import '../features/schedules/presentation/schedules_screen.dart';
import '../features/subusers/presentation/subusers_screen.dart';
import '../features/network/presentation/network_screen.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/settings/presentation/server_settings_screen.dart';
import '../features/settings/presentation/server_backups_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/admin/presentation/admin_users_screen.dart';
import '../features/admin/presentation/admin_servers_screen.dart';
import '../features/admin/presentation/admin_nodes_screen.dart';
import '../features/admin/presentation/admin_nests_screen.dart';
import '../features/admin/presentation/admin_plans_screen.dart';
import '../features/admin/presentation/plan_form_screen.dart';
import '../features/admin/presentation/admin_orders_screen.dart';
import '../features/home/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAdmin = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      if (authState is AuthUnauthenticated && !isLoggingIn) return '/login';
      if (authState is AuthAuthenticated && isLoggingIn) return '/home/plans';
      if (state.matchedLocation.startsWith('/admin') && !isAdmin) return '/home/plans';
      if (state.matchedLocation == '/') return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home/plans',
            builder: (context, state) => const PlansScreen(),
          ),
          GoRoute(
            path: '/home/servers',
            builder: (context, state) => const ServerListScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/plans/:slug',
        builder: (context, state) => PlanDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/servers/:id',
        builder: (context, state) => ServerDetailScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/console',
        builder: (context, state) => ConsoleScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/files',
        builder: (context, state) => FileManagerScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/files/editor',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final filePath = state.uri.queryParameters['path'] ?? 'server.properties';
          return FileEditorScreen(serverId: serverId, filePath: filePath);
        },
      ),
      GoRoute(
        path: '/servers/:id/databases',
        builder: (context, state) => DatabasesScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/schedules',
        builder: (context, state) => SchedulesScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/subusers',
        builder: (context, state) => SubusersScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/network',
        builder: (context, state) => NetworkScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/activity',
        builder: (context, state) => ActivityScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/settings',
        builder: (context, state) => ServerSettingsScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servers/:id/backups',
        builder: (context, state) => ServerBackupsScreen(serverId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/servers',
        builder: (context, state) => const AdminServersScreen(),
      ),
      GoRoute(
        path: '/admin/nodes',
        builder: (context, state) => const AdminNodesScreen(),
      ),
      GoRoute(
        path: '/admin/nests',
        builder: (context, state) => const AdminNestsScreen(),
      ),
      GoRoute(
        path: '/admin/plans',
        builder: (context, state) => const AdminPlansScreen(),
      ),
      GoRoute(
        path: '/admin/plans/create',
        builder: (context, state) => const PlanFormScreen(),
      ),
      GoRoute(
        path: '/admin/plans/:id/edit',
        builder: (context, state) => PlanFormScreen(planId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
    ],
  );
});
