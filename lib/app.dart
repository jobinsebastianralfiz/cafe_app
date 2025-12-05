import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/env_config.dart';
import 'routes/app_router.dart';

/// Main Cafe App - Role-Based Multi-App System
/// Supports: Customer, Admin, Kitchen, Waiter, Delivery, Staff
class CafeApp extends ConsumerWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Cafe App',
      debugShowCheckedModeBanner: false
      ,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
