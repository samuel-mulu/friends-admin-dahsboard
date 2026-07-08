import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String phoneNumber,
    required String password,
    required String deviceId,
  }) async {
    return _apiClient.post<AuthSession>(
      '/auth/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'deviceId': deviceId,
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
    return _apiClient.post<AuthSession>(
      '/auth/register',
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'password': password,
        'otp': otp,
        'deviceId': deviceId,
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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
