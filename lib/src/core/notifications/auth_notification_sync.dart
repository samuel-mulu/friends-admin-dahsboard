import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_notification_service.dart';
import 'notification_token_repository.dart';

class AuthNotificationSync {
  AuthNotificationSync(this._notifications, this._repository);

  final FirebaseNotificationService _notifications;
  final NotificationTokenRepository _repository;

  bool _isListeningForRefresh = false;

  Future<void> syncAuthenticatedSession() async {
    try {
      if (!_notifications.isSupportedPlatform) {
        _log('skip sync: unsupported platform');
        return;
      }

      _log('sync start');
      await _notifications.initialize();

      final granted = await _notifications.requestPermission();
      _log('permission granted=$granted');
      if (!granted) {
        return;
      }

      if (!_isListeningForRefresh) {
        _log('attach token refresh listener');
        await _notifications.listenForTokenRefresh((nextToken) async {
          if (nextToken.isEmpty) {
            _log('ignore empty refreshed token');
            return;
          }

          _log('token refreshed suffix=${_suffix(nextToken)}');
          await _repository.registerDeviceToken(
            token: nextToken,
            platform: _notifications.platform,
          );
        });
        _isListeningForRefresh = true;
      }

      final token = await _notifications.getToken();
      if (token == null || token.isEmpty) {
        _log('no token received');
        return;
      }

      _log('register current token suffix=${_suffix(token)}');
      await _repository.registerDeviceToken(
        token: token,
        platform: _notifications.platform,
      );
      _log('sync complete');
    } catch (error) {
      _log('sync failed: $error');
    }
  }

  Future<void> stop() async {
    _isListeningForRefresh = false;
    _log('stop token refresh listener');
    await _notifications.stopTokenRefreshListener();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Notifications/AuthSync] $message');
    }
  }

  String _suffix(String token) {
    if (token.length <= 8) {
      return token;
    }

    return token.substring(token.length - 8);
  }
}

final authNotificationSyncProvider = Provider<AuthNotificationSync>((ref) {
  return AuthNotificationSync(
    ref.read(firebaseNotificationServiceProvider),
    ref.read(notificationTokenRepositoryProvider),
  );
});
