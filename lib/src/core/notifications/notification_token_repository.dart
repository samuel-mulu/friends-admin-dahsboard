import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

class NotificationTokenRepository {
  NotificationTokenRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    _log('register token platform=$platform suffix=${_suffix(token)}');
    await _apiClient.post<Object?>(
      '/notifications/register-device',
      data: {
        'token': token,
        'platform': platform,
      },
      decoder: (rawData) => rawData,
    );
    _log('register token success');
  }

  Future<void> unregisterDeviceToken({required String token}) async {
    _log('unregister token suffix=${_suffix(token)}');
    await _apiClient.delete<Object?>(
      '/notifications/register-device',
      data: {'token': token},
      decoder: (rawData) => rawData,
    );
    _log('unregister token success');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Notifications/API] $message');
    }
  }

  String _suffix(String token) {
    if (token.length <= 8) {
      return token;
    }

    return token.substring(token.length - 8);
  }
}

final notificationTokenRepositoryProvider =
    Provider<NotificationTokenRepository>((ref) {
      return NotificationTokenRepository(ref.watch(apiClientProvider));
    });
