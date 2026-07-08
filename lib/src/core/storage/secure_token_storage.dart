import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/domain/user_profile.dart';

class SecureTokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey = 'device_id';
  static const _userProfileKey = 'user_profile';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<AuthSession?> readCachedSession() async {
    final accessToken = await readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final rawUser = await _storage.read(key: _userProfileKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AuthSession(
        accessToken: accessToken,
        refreshToken: await readRefreshToken(),
        user: UserProfile.fromJson(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> ensureDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    const uuid = Uuid();
    final generated = uuid.v4();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  Future<void> saveSession({
    required AuthSession session,
    required String deviceId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      if (session.refreshToken != null && session.refreshToken!.trim().isNotEmpty)
        _storage.write(key: _refreshTokenKey, value: session.refreshToken)
      else
        _storage.delete(key: _refreshTokenKey),
      _storage.write(
        key: _userProfileKey,
        value: jsonEncode(session.user.toJson()),
      ),
      _storage.write(key: _deviceIdKey, value: deviceId),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userProfileKey),
    ]);
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage(const FlutterSecureStorage());
});
