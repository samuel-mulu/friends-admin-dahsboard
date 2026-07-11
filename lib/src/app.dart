import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/device/screen_awake_controller.dart';
import 'core/l10n/fallback_global_localizations.dart';
import 'core/notifications/auth_notification_sync.dart';
import 'core/notifications/firebase_notification_service.dart';
import 'core/notifications/push_route_resolver.dart';
import 'core/routing/app_router.dart';
import 'core/sync/app_resume_sync.dart';
import 'core/sync/resume_sync_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/version/app_update_dialog.dart';
import 'core/version/version_check_controller.dart';
import 'core/version/version_update_resume_recheck.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/widgets/pin_setup_dialog.dart';
import 'features/auth/security/app_lock_controller.dart';
import 'features/settings/presentation/providers/locale_provider.dart';
import 'features/settings/presentation/providers/theme_mode_provider.dart';
import 'features/games/domain/game_rule_localized_name.dart';

class FriendsBingoApp extends ConsumerStatefulWidget {
  const FriendsBingoApp({super.key});

  @override
  ConsumerState<FriendsBingoApp> createState() => _FriendsBingoAppState();
}

class _FriendsBingoAppState extends ConsumerState<FriendsBingoApp>
    with WidgetsBindingObserver {
  bool _isShowingPinSetup = false;
  StreamSubscription<dynamic>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final lifecycleState =
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
      unawaited(
        ref
            .read(screenAwakeControllerProvider.notifier)
            .syncLifecycle(lifecycleState),
      );
    });
    _notificationTapSubscription = ref
        .read(firebaseNotificationServiceProvider)
        .notificationTapStream
        .listen((message) {
          if (!mounted) {
            return;
          }

          ref.read(appRouterProvider).go(resolvePushRoute(message));
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(versionCheckReadyProvider.notifier).markReady();
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_bootstrapVersionCheck());
    }
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref.read(screenAwakeControllerProvider.notifier).syncLifecycle(state),
    );

    final controller = ref.read(appLockControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        AppBackgroundResumeGate.onAppBackgrounded();
        controller.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        controller.onAppResumed();
        unawaited(syncAppAfterResume(ref));
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            ref
                .read(versionUpdateResumeRecheckControllerProvider.notifier)
                .consumeRecheck()) {
          unawaited(_recheckForceUpdateAfterBrowser());
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    ref.watch(gameRuleNamesRepositoryProvider);

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
        unawaited(
          ref.read(authNotificationSyncProvider).syncAuthenticatedSession(),
        );
        navigateAfterAuthentication(router);
      });
    });

    ref.listen<AppLockState>(appLockControllerProvider, (previous, next) {
      if (!next.shouldPromptForPinSetup || _isShowingPinSetup) {
        return;
      }

      _isShowingPinSetup = true;
      Future.microtask(() async {
        if (!mounted) {
          _isShowingPinSetup = false;
          return;
        }
        final dialogContext = router.routerDelegate.navigatorKey.currentContext;
        if (dialogContext == null || !dialogContext.mounted) {
          _isShowingPinSetup = false;
          return;
        }

        await showDialog<void>(
          context: dialogContext,
          barrierDismissible: false,
          builder: (_) => const PinSetupDialog(),
        );

        _isShowingPinSetup = false;
      });
    });

    return MaterialApp.router(
      title: 'Friends Bingo-online',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...fallbackGlobalLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => ForceUpdateGate(child: child),
    );
  }

  Future<void> _bootstrapVersionCheck() async {
    await ref.read(versionCheckControllerProvider.notifier).check();
  }

  Future<void> _recheckForceUpdateAfterBrowser() async {
    if (!mounted) {
      return;
    }

    await ref.read(versionCheckControllerProvider.notifier).check();
  }
}
