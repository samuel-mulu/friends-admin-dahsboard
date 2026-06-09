import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/settings/presentation/providers/theme_mode_provider.dart';

class FriendsBingoApp extends ConsumerWidget {
  const FriendsBingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.isInitializing) {
        return;
      }

      final wasAuthenticated = previous?.session != null;
      final isAuthenticated = next.session != null;
      if (wasAuthenticated || !isAuthenticated) {
        return;
      }

      Future.microtask(() {
        navigateAfterAuthentication(router);
      });
    });

    return MaterialApp.router(
      title: 'Friends Bingo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
