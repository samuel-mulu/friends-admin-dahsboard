import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/games/presentation/screens/game_history_screen.dart';
import '../../features/games/presentation/screens/live_game_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_shell_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shared/presentation/screens/splash_screen.dart';
import '../../features/wallet/presentation/screens/deposit_history_screen.dart';
import '../../features/wallet/presentation/screens/deposit_screen.dart';
import '../../features/wallet/presentation/screens/wallet_transactions_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/wallet/presentation/screens/withdraw_history_screen.dart';
import '../../features/wallet/presentation/screens/withdraw_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/loading',
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(initialMessage: state.uri.queryParameters['message']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                builder: (context, state) => const LiveGameScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const GameHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
                routes: [
                  GoRoute(
                    path: 'deposit',
                    builder: (context, state) => const DepositScreen(),
                  ),
                  GoRoute(
                    path: 'deposits',
                    builder: (context, state) => const DepositHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'withdraw',
                    builder: (context, state) => const WithdrawScreen(),
                  ),
                  GoRoute(
                    path: 'withdrawals',
                    builder: (context, state) => const WithdrawHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'transactions',
                    builder: (context, state) =>
                        const WalletTransactionsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isInitializing = authState.isInitializing;
      final isAuthenticated = authState.session != null;
      final location = state.matchedLocation;
      const authLocations = {'/login', '/register', '/forgot-password'};
      final isAuthLocation = authLocations.contains(location);

      if (isInitializing) {
        return location == '/loading' ? null : '/loading';
      }

      if (!isAuthenticated) {
        return isAuthLocation ? null : '/login';
      }

      if (location == '/loading' || isAuthLocation) {
        return '/games';
      }

      return null;
    },
  );
});
