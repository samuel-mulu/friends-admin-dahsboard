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
    this.chainDebug = false,
    this.bigGameDebug = false,
    this.debug = false,
    this.telebirrDepositDebug = false,
  });

  final String apiBaseUrl;
  final String socketBaseUrl;

  /// Verbose live-game / auto-call socket tracing (debug builds only).
  final bool realtimeDebug;

  /// Chain Game round-boundary tracing (debug builds only).
  final bool chainDebug;

  /// Big Game round / registration-window tracing (debug builds only).
  final bool bigGameDebug;

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
    final chainDebug =
        const bool.fromEnvironment('CHAIN_DEBUG') ||
        _envBool('CHAIN_DEBUG');
    final bigGameDebug =
        const bool.fromEnvironment('BIG_GAME_DEBUG') ||
        _envBool('BIG_GAME_DEBUG');
    final debug =
        const bool.fromEnvironment('DEBUG') || _envBool('DEBUG');
    final telebirrDepositDebug =
        const bool.fromEnvironment('TELEBIRR_DEPOSIT_DEBUG') ||
        _envBool('TELEBIRR_DEPOSIT_DEBUG');

    if (apiBaseUrlOverride.isEmpty) {
      throw StateError(
        'Missing required environment variable: API_BASE_URL.\n'
        'Please define API_BASE_URL in your .env file (see .env.example) '
        'or pass it via --dart-define=API_BASE_URL=...',
      );
    }

    final apiBaseUrl = _normalize(apiBaseUrlOverride);
    _validateReleaseApiBaseUrl(apiBaseUrl: apiBaseUrl);
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
      chainDebug: chainDebug,
      bigGameDebug: bigGameDebug,
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

  static String _normalize(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static void _validateReleaseApiBaseUrl({
    required String apiBaseUrl,
  }) {
    if (!kReleaseMode) {
      return;
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
