// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/screens/expense_list_screen.dart';
import '../../features/expenses/presentation/screens/receipt_capture_screen.dart';
import '../../features/expenses/presentation/screens/receipt_confirm_screen.dart';
import '../../features/insights/presentation/screens/budgets_screen.dart';
import '../../features/insights/presentation/screens/dashboard_screen.dart';
import '../widgets/home_shell.dart';

part 'app_router.g.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final refreshStream = _GoRouterRefreshStream(
    ref.watch(authStateProvider.stream),
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final goingToAuth =
          state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';

      if (!isLoggedIn && !goingToAuth) return '/sign-in';
      if (isLoggedIn && goingToAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) =>
            AddExpenseScreen(expense: state.extra as Expense?),
      ),
      GoRoute(
        path: '/capture-receipt',
        builder: (context, state) => const ReceiptCaptureScreen(),
      ),
      GoRoute(
        path: '/confirm-receipt',
        builder: (context, state) {
          final args = state.extra! as ReceiptConfirmArgs;
          return ReceiptConfirmScreen(args: args);
        },
      ),
    ],
  );
}
