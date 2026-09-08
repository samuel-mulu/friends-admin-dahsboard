import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_device_session.dart';
import '../domain/auth_session.dart';
import '../domain/user_profile.dart';
import 'device_meta.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String phoneNumber,
    required String password,
    required String deviceId,
  }) async {
    final meta = await buildAuthDeviceMeta();
    return _apiClient.post<AuthSession>(
      '/auth/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'deviceId': deviceId,
        ...meta.toJson(),
      },
      decoder: _decodeSession,
    );
  }

  Future<AuthSession> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String otp,
    required String deviceId,
  }) async {
    final meta = await buildAuthDeviceMeta();
    return _apiClient.post<AuthSession>(
      '/auth/register',
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'password': password,
        'otp': otp,
        'deviceId': deviceId,
        ...meta.toJson(),
      },
      decoder: _decodeSession,
    );
  }

  Future<String> requestRegisterOtp({required String phoneNumber}) {
    return _apiClient.post<String>(
      '/auth/request-register-otp',
      data: {'phoneNumber': phoneNumber},
      decoder: _decodeMessage,
    );
  }

  Future<String> requestPasswordResetOtp({required String phoneNumber}) {
    return _apiClient.post<String>(
      '/auth/request-password-reset-otp',
      data: {'phoneNumber': phoneNumber},
      decoder: _decodeMessage,
    );
  }

  Future<String> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) {
    return _apiClient.post<String>(
      '/auth/reset-password',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      },
      decoder: _decodeMessage,
    );
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    String? refreshToken,
  }) {
    return _apiClient.post<String>(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      },
      decoder: _decodeMessage,
    );
  }

  Future<String> requestSetPasswordOtp() {
    return _apiClient.post<String>(
      '/auth/request-set-password-otp',
      data: const {},
      decoder: _decodeMessage,
    );
  }

  Future<String> setPassword({
    required String otp,
    required String newPassword,
    String? refreshToken,
  }) {
    return _apiClient.post<String>(
      '/auth/set-password',
      data: {
        'otp': otp,
        'newPassword': newPassword,
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      },
      decoder: _decodeMessage,
    );
  }

  Future<List<AuthDeviceSession>> listSessions({
    required String refreshToken,
    required String deviceId,
  }) {
    return _apiClient.get<List<AuthDeviceSession>>(
      '/auth/sessions',
      queryParameters: {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      },
      decoder: (raw) {
        if (raw is! Map<String, dynamic>) {
          throw StateError('Invalid sessions response.');
        }
        final sessions = raw['sessions'];
        if (sessions is! List) {
          throw StateError('Invalid sessions response.');
        }
        return sessions
            .whereType<Map<String, dynamic>>()
            .map(AuthDeviceSession.fromJson)
            .toList();
      },
    );
  }

  Future<String> revokeSession(String sessionId) {
    return _apiClient.delete<String>(
      '/auth/sessions/$sessionId',
      decoder: _decodeMessage,
    );
  }

  Future<String> logoutOtherSessions({
    required String refreshToken,
    required String deviceId,
  }) {
    return _apiClient.post<String>(
      '/auth/sessions/logout-others',
      data: {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      },
      decoder: _decodeMessage,
    );
  }

  Future<TelegramStartResult> telegramStart({
    required Map<String, dynamic> telegram,
    required String deviceId,
  }) async {
    final meta = await buildAuthDeviceMeta();
    return _apiClient.post<TelegramStartResult>(
      '/auth/telegram/start',
      data: {
        'telegram': telegram,
        'deviceId': deviceId,
        ...meta.toJson(),
      },
      decoder: TelegramStartResult.fromJson,
    );
  }

  Future<String> telegramRequestOtp({
    required String ticket,
    required String phoneNumber,
  }) {
    return _apiClient.post<String>(
      '/auth/telegram/request-otp',
      data: {
        'ticket': ticket,
        'phoneNumber': phoneNumber,
      },
      decoder: _decodeMessage,
    );
  }

  Future<AuthSession> telegramComplete({
    required String ticket,
    required String phoneNumber,
    required String otp,
    required String deviceId,
  }) async {
    final meta = await buildAuthDeviceMeta();
    return _apiClient.post<AuthSession>(
      '/auth/telegram/complete',
      data: {
        'ticket': ticket,
        'phoneNumber': phoneNumber,
        'otp': otp,
        'deviceId': deviceId,
        ...meta.toJson(),
      },
      decoder: _decodeSession,
    );
  }

  Future<UserProfile> linkTelegram({
    required Map<String, dynamic> telegram,
  }) {
    return _apiClient.post<UserProfile>(
      '/auth/telegram/link',
      data: {'telegram': telegram},
      decoder: (raw) {
        if (raw is! Map<String, dynamic>) {
          throw StateError('Invalid telegram link response.');
        }
        final user = raw['user'];
        if (user is! Map<String, dynamic>) {
          throw StateError('Invalid telegram link response.');
        }
        return UserProfile.fromJson(user);
      },
    );
  }

  Future<UserProfile> unlinkTelegram() {
    return _apiClient.post<UserProfile>(
      '/auth/telegram/unlink',
      data: const {},
      decoder: (raw) {
        if (raw is! Map<String, dynamic>) {
          throw StateError('Invalid telegram unlink response.');
        }
        final user = raw['user'];
        if (user is! Map<String, dynamic>) {
          throw StateError('Invalid telegram unlink response.');
        }
        return UserProfile.fromJson(user);
      },
    );
  }

  AuthSession _decodeSession(Object? rawData) {
    if (rawData is! Map<String, dynamic>) {
      throw StateError('Invalid auth response.');
    }

    return AuthSession.fromJson(rawData);
  }

  String _decodeMessage(Object? rawData) {
    if (rawData is! Map<String, dynamic>) {
      throw StateError('Invalid message response.');
    }

    final message = rawData['message'];
    if (message is! String) {
      throw StateError('Invalid message response.');
    }

    return message;
  }
}

sealed class TelegramStartResult {
  const TelegramStartResult();

  factory TelegramStartResult.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw StateError('Invalid telegram start response.');
    }
    final status = raw['status'];
    if (status == 'authenticated') {
      return TelegramAuthenticated(AuthSession.fromJson(raw));
    }
    if (status == 'needs_phone') {
      final ticket = raw['ticket'];
      if (ticket is! String) {
        throw StateError('Invalid telegram ticket.');
      }
      return TelegramNeedsPhone(ticket: ticket);
    }
    throw StateError('Unknown telegram start status.');
  }
}

class TelegramAuthenticated extends TelegramStartResult {
  const TelegramAuthenticated(this.session);
  final AuthSession session;
}

class TelegramNeedsPhone extends TelegramStartResult {
  const TelegramNeedsPhone({required this.ticket});
  final String ticket;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
