import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';
import '../domain/user_profile.dart';

class SessionRepository {
  SessionRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
      );

      final envelope = _decodeEnvelope(response.data);
      final data = envelope.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'Invalid refresh response.');
      }

      final accessToken = data['accessToken'];
      final nextRefreshToken = data['refreshToken'];
      if (accessToken is! String) {
        throw ApiException(message: 'Invalid refresh response.');
      }

      final userJson = data['user'];
      final user = userJson is Map<String, dynamic>
          ? UserProfile.fromJson(userJson)
          : await getCurrentUser(accessToken);

      return AuthSession(
        accessToken: accessToken,
        refreshToken: nextRefreshToken is String && nextRefreshToken.isNotEmpty
            ? nextRefreshToken
            : refreshToken,
        user: user,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ApiException.fromCaughtError(error), stackTrace);
    }
  }

  Future<void> logout({
    required String refreshToken,
    required String deviceId,
    String? accessToken,
  }) async {
    try {
      await _dio.post<Object?>(
        '/auth/logout',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
        options: accessToken == null || accessToken.isEmpty
            ? null
            : Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ApiException.fromCaughtError(error), stackTrace);
    }
  }

  Future<UserProfile> getCurrentUser(String accessToken) async {
    try {
      final response = await _dio.get<Object?>(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final envelope = _decodeEnvelope(response.data);
      final data = envelope.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'Invalid user response.');
      }

      return UserProfile.fromJson(data);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ApiException.fromCaughtError(error), stackTrace);
    }
  }

  ApiEnvelope<Object?> _decodeEnvelope(Object? rawResponse) {
    if (rawResponse is! Map<String, dynamic>) {
      throw ApiException(message: 'Unexpected server response.');
    }

    final envelope = ApiEnvelope<Object?>.fromJson(rawResponse, (data) => data);
    if (!envelope.success) {
      throw ApiException(message: 'Request failed.');
    }

    return envelope;
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(rawDioProvider));
});
