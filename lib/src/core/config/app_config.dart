import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  AppConfig({required this.apiBaseUrl, required this.socketBaseUrl});

  final String apiBaseUrl;
  final String socketBaseUrl;

  factory AppConfig.fromEnvironment() {
    const apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
    const socketUrlOverride = String.fromEnvironment('SOCKET_URL');
    const legacySocketBaseUrlOverride = String.fromEnvironment(
      'SOCKET_BASE_URL',
    );
    final apiBaseUrl = _normalize(
      apiBaseUrlOverride.isNotEmpty
          ? apiBaseUrlOverride
          : _defaultApiBaseUrlForPlatform(),
    );
    _validateReleaseApiBaseUrl(
      apiBaseUrl: apiBaseUrl,
      hasOverride: apiBaseUrlOverride.isNotEmpty,
    );
    final socketBaseUrl = _normalize(
      socketUrlOverride.isNotEmpty
          ? socketUrlOverride
          : legacySocketBaseUrlOverride.isNotEmpty
          ? legacySocketBaseUrlOverride
          : apiBaseUrl,
    );
    _validateReleaseSocketBaseUrl(socketBaseUrl);

    return AppConfig(apiBaseUrl: apiBaseUrl, socketBaseUrl: socketBaseUrl);
  }

  static String _defaultApiBaseUrlForPlatform() {
    if (kIsWeb) {
      return 'http://localhost:3002';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3002';
    }
    return 'http://localhost:3002';
  }

  static String _normalize(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static void _validateReleaseApiBaseUrl({
    required String apiBaseUrl,
    required bool hasOverride,
  }) {
    if (!kReleaseMode) {
      return;
    }

    if (!hasOverride) {
      throw StateError(
        'API_BASE_URL is required for release builds. '
        'Do not ship a release build with localhost defaults.',
      );
    }

    _validateReleaseUrl(name: 'API_BASE_URL', url: apiBaseUrl);
  }

  static void _validateReleaseSocketBaseUrl(String socketBaseUrl) {
    if (!kReleaseMode) {
      return;
    }

    _validateReleaseUrl(name: 'SOCKET_URL', url: socketBaseUrl);
  }

  static void _validateReleaseUrl({required String name, required String url}) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase();
    final isLocalHost =
        host == null ||
        host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2';

    if (isLocalHost) {
      throw StateError(
        '$name must point to a production host in release builds. '
        'Current value: $url',
      );
    }
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
