import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/expenses/presentation/providers/expense_providers.dart';

class SpendSenseApp extends ConsumerWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activates the connectivity-regained sync trigger for the app's lifetime.
    ref.watch(connectivitySyncTriggerProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SpendSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
