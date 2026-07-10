import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App configuration from `--dart-define`, bundled `.env`, or debug defaults.
///
/// Resolution order for each key:
/// 1. `--dart-define` / `--dart-define-from-file` (compile-time)
/// 2. bundled `.env` asset (runtime via flutter_dotenv)
/// 3. platform localhost defaults (debug only)
///
/// Local development:
/// ```bash
/// flutter run -d chrome --dart-define-from-file=.env
/// ```
///
/// Release APK:
/// ```bash
/// flutter build apk --release
/// ```
/// Ensure `.env` exists with production URLs before building — it is bundled
/// into the app via [pubspec.yaml].
class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.socketBaseUrl,
    this.realtimeDebug = false,
    this.debug = false,
    this.telebirrDepositDebug = false,
  });

  final String apiBaseUrl;
  final String socketBaseUrl;

  /// Verbose live-game / auto-call socket tracing (debug builds only).
  final bool realtimeDebug;

  /// General debug tracing (debug builds only).
  final bool debug;

  /// Telebirr deposit verification tracing (debug builds only).
  final bool telebirrDepositDebug;

  bool get telebirrDebugEnabled =>
      debug || telebirrDepositDebug || realtimeDebug;

  factory AppConfig.fromEnvironment() {
    const apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
    const socketUrlDefine = String.fromEnvironment('SOCKET_URL');
    const legacySocketBaseUrlDefine = String.fromEnvironment('SOCKET_BASE_URL');

    final apiBaseUrlOverride = _firstNonEmpty([
      apiBaseUrlDefine,
      _envString('API_BASE_URL'),
    ]);
    final socketUrlOverride = _firstNonEmpty([
      socketUrlDefine,
      _envString('SOCKET_URL'),
    ]);
    final legacySocketBaseUrlOverride = _firstNonEmpty([
      legacySocketBaseUrlDefine,
      _envString('SOCKET_BASE_URL'),
    ]);

    final realtimeDebug =
        const bool.fromEnvironment('REALTIME_DEBUG') ||
        _envBool('REALTIME_DEBUG');
    final debug =
        const bool.fromEnvironment('DEBUG') || _envBool('DEBUG');
    final telebirrDepositDebug =
        const bool.fromEnvironment('TELEBIRR_DEPOSIT_DEBUG') ||
        _envBool('TELEBIRR_DEPOSIT_DEBUG');

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

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      socketBaseUrl: socketBaseUrl,
      realtimeDebug: realtimeDebug,
      debug: debug,
      telebirrDepositDebug: telebirrDepositDebug,
    );
  }

  static String _envString(String key) {
    return dotenv.maybeGet(key)?.trim() ?? '';
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static bool _envBool(String key) {
    final value = _envString(key).toLowerCase();
    return value == 'true' || value == '1';
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
        'Add production URLs to .env before building, e.g. '
        'Copy-Item .env.production.example .env',
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
        'Current value: $url. '
        'Update .env with production URLs before building.',
      );
    }
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
