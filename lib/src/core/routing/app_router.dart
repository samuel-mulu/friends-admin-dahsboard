import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/version/version_check_controller.dart';
import '../../core/version/version_check_state.dart';
import '../../core/widgets/app_back_confirm_scope.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/unlock_screen.dart';
import '../../features/auth/security/app_lock_controller.dart';
import '../../features/games/presentation/screens/big_game_screen.dart';
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
import '../../features/support/presentation/screens/contact_us_screen.dart';
import '../../features/support/presentation/screens/my_feedback_screen.dart';
import 'auth_route_guard.dart';
import 'go_router_refresh.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _gamesBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'gamesBranch',
);
final _homeBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeBranch',
);
final _walletBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'walletBranch',
);
final _profileBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'profileBranch',
);

bool _shouldHoldOnLoadingForVersionCheck(Ref ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }

  return ref.read(versionCheckControllerProvider).kind == VersionCheckKind.force;
}

String? _authRedirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authControllerProvider);
  final lockState = ref.read(appLockControllerProvider);
  final isInitializing = authState.isInitializing;
  final isLockInitializing = lockState.isInitializing;
  final isAuthenticated = authState.session != null;
  final isLocked = lockState.isLocked && lockState.hasPin;
  final location = state.matchedLocation;

  if (_shouldHoldOnLoadingForVersionCheck(ref)) {
    return location == '/loading' ? null : '/loading';
  }

  if (isInitializing || isLockInitializing) {
    return location == '/loading' ? null : '/loading';
  }

  if (isAuthenticated && isLocked) {
    if (location == '/unlock') {
      return null;
    }

    return '/unlock?redirect=${Uri.encodeComponent(location)}';
  }

  if (!isAuthenticated) {
    if (location == '/loading') {
      return '/games';
    }

    if (kAuthLocations.contains(location) ||
        kGuestLocations.contains(location)) {
      return null;
    }

    if (location == '/unlock') {
      return '/games';
    }

    if (isProtectedLocation(location)) {
      return loginPathWithRedirect(location);
    }

    return '/games';
  }

  if (location == '/loading') {
    return redirectAfterAuth(state);
  }

  if (location == '/unlock') {
    return redirectAfterAuth(state);
  }

  return null;
}

String redirectAfterAuth(GoRouterState state) {
  final redirect = state.uri.queryParameters['redirect'];
  if (redirect != null &&
      redirect.startsWith('/') &&
      !kAuthLocations.contains(redirect)) {
    return redirect;
  }

  return '/games';
}

void navigateAfterAuthentication(GoRouter router) {
  final location = router.state.matchedLocation;
  if (!kAuthLocations.contains(location)) {
    return;
  }

  router.go(redirectAfterAuth(router.state));
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/loading',
    refreshListenable: refresh,
    redirect: (context, state) => _authRedirect(ref, state),
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) =>
            appRouteWithBackConfirm(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => appRouteWithBackConfirm(
          LoginScreen(initialMessage: state.uri.queryParameters['message']),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            appRouteWithBackConfirm(const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            appRouteWithBackConfirm(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) =>
            appRouteWithBackConfirm(const UnlockScreen()),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) =>
            appRouteWithBackConfirm(const ContactUsScreen()),
      ),
      GoRoute(
        path: '/support/my-feedback',
        builder: (context, state) =>
            appRouteWithBackConfirm(const MyFeedbackScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _gamesBranchNavigatorKey,
            routes: [
              GoRoute(
                path: '/games',
                builder: (context, state) => appRouteWithBackConfirm(
                  LiveGameScreen(
                    gameId: state.uri.queryParameters['sessionId'],
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) =>
                        appRouteWithBackConfirm(const GameHistoryScreen()),
                  ),
                  GoRoute(
                    path: 'big-game',
                    builder: (context, state) =>
                        appRouteWithBackConfirm(const BigGameScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _homeBranchNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) =>
                    appRouteWithBackConfirm(const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _walletBranchNavigatorKey,
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) =>
                    appRouteWithBackConfirm(const WalletScreen()),
                routes: [
                  GoRoute(
                    path: 'deposit',
                    builder: (context, state) =>
                        appRouteWithBackConfirm(const DepositScreen()),
                  ),
                  GoRoute(
                    path: 'deposits',
                    builder: (context, state) =>
                        appRouteWithBackConfirm(const DepositHistoryScreen()),
                  ),
                  GoRoute(
                    path: 'withdraw',
                    builder: (context, state) =>
                        appRouteWithBackConfirm(const WithdrawScreen()),
                  ),
                  GoRoute(
                    path: 'withdrawals',
                    builder: (context, state) =>
                        appRouteWithBackConfirm(const WithdrawHistoryScreen()),
                  ),
                  GoRoute(
                    path: 'transactions',
                    builder: (context, state) => appRouteWithBackConfirm(
                      const WalletTransactionsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileBranchNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    appRouteWithBackConfirm(const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
