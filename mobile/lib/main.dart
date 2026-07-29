import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';

void main() {
  runApp(const ProviderScope(child: RenCloudApp()));
}

class RenCloudApp extends ConsumerWidget {
  const RenCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: Constants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Night mode default
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
