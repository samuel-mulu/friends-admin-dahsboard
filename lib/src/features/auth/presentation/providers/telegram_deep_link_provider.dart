import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../screens/telegram_phone_link_screen.dart';

final telegramDeepLinkListenerProvider = Provider<void>((ref) {
  if (kIsWeb) {
    return;
  }

  final appLinks = AppLinks();
  StreamSubscription<Uri>? sub;

  Future<void> handleUri(Uri uri) async {
    final payload = parseTelegramAuthUri(uri);
    if (payload == null) {
      return;
    }

    final session = ref.read(authControllerProvider).session;
    final router = ref.read(appRouterProvider);

    if (session != null) {
      await ref
          .read(authControllerProvider.notifier)
          .linkTelegramAccount(payload);
      return;
    }

    final result = await ref
        .read(authControllerProvider.notifier)
        .telegramStart(payload);

    if (result is TelegramNeedsPhone) {
      router.go(
        Uri(
          path: '/auth/telegram-phone',
          queryParameters: {'ticket': result.ticket},
        ).toString(),
      );
      return;
    }

    if (result is TelegramAuthenticated ||
        ref.read(authControllerProvider).session != null) {
      navigateAfterAuthentication(router);
    }
  }

  () async {
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        await handleUri(initial);
      }
    } catch (error) {
      if (kDebugMode) {
        AppLogger.debug('TelegramDeepLink', 'initial link failed: $error');
      }
    }
  }();

  sub = appLinks.uriLinkStream.listen(
    (uri) {
      unawaited(handleUri(uri));
    },
    onError: (Object error) {
      if (kDebugMode) {
        AppLogger.debug('TelegramDeepLink', 'stream error: $error');
      }
    },
  );

  ref.onDispose(() {
    unawaited(sub?.cancel() ?? Future<void>.value());
  });
});
