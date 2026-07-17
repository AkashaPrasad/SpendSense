import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/expenses/presentation/providers/expense_providers.dart';

class SpendSenseApp extends ConsumerWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activates the connectivity-regained sync trigger for the app's lifetime.
    ref.watch(connectivitySyncTriggerProvider);

    // Don't mount the router (and therefore any protected screen) until we
    // actually know whether the user is signed in. Firebase's auth state
    // resolves asynchronously, so without this gate, go_router's redirect
    // can race it and briefly render the dashboard — and its API calls —
    // before the sign-in check catches up.
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

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
