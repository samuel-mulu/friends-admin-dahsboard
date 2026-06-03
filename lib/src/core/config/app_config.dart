import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  AppConfig({required this.apiBaseUrl, required this.socketBaseUrl});

  final String apiBaseUrl;
  final String socketBaseUrl;

  factory AppConfig.fromEnvironment() {
    const defaultApiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000',
    );
    const socketUrlOverride = String.fromEnvironment('SOCKET_URL');
    const legacySocketBaseUrlOverride = String.fromEnvironment(
      'SOCKET_BASE_URL',
    );
    final apiBaseUrl = _normalize(defaultApiBaseUrl);
    final socketBaseUrl = _normalize(
      socketUrlOverride.isNotEmpty
          ? socketUrlOverride
          : legacySocketBaseUrlOverride.isNotEmpty
          ? legacySocketBaseUrlOverride
          : apiBaseUrl,
    );

    return AppConfig(apiBaseUrl: apiBaseUrl, socketBaseUrl: socketBaseUrl);
  }

  static String _normalize(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
