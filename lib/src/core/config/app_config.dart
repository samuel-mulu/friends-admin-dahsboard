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
    this.cartelaScrollDebug = false,
    this.chainDebug = false,
    this.bigGameDebug = false,
    this.debug = false,
    this.telebirrDepositDebug = false,
  });

  final String apiBaseUrl;
  final String socketBaseUrl;

  /// Verbose live-game / auto-call socket tracing (debug builds only).
  final bool realtimeDebug;

  /// Live cartela list scroll / rebuild tracing (debug builds only).
  final bool cartelaScrollDebug;

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
    final apiBaseUrlOverride = _resolveString(
      key: 'API_BASE_URL',
      compileTimeValue: const String.fromEnvironment('API_BASE_URL'),
    );
    final socketUrlOverride = _resolveString(
      key: 'SOCKET_URL',
      compileTimeValue: const String.fromEnvironment('SOCKET_URL'),
    );
    final legacySocketBaseUrlOverride = _resolveString(
      key: 'SOCKET_BASE_URL',
      compileTimeValue: const String.fromEnvironment('SOCKET_BASE_URL'),
    );

    final realtimeDebug =
        const bool.fromEnvironment('REALTIME_DEBUG') ||
        _envBool('REALTIME_DEBUG');
    final cartelaScrollDebug =
        const bool.fromEnvironment('CARTELA_SCROLL_DEBUG') ||
        _envBool('CARTELA_SCROLL_DEBUG');
    final chainDebug =
        const bool.fromEnvironment('CHAIN_DEBUG') || _envBool('CHAIN_DEBUG');
    final bigGameDebug =
        const bool.fromEnvironment('BIG_GAME_DEBUG') ||
        _envBool('BIG_GAME_DEBUG');
    final debug = const bool.fromEnvironment('DEBUG') || _envBool('DEBUG');
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
      cartelaScrollDebug: cartelaScrollDebug,
      chainDebug: chainDebug,
      bigGameDebug: bigGameDebug,
      debug: debug,
      telebirrDepositDebug: telebirrDepositDebug,
    );
  }

  static String _envString(String key) {
    try {
      return dotenv.maybeGet(key)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool _resolveBool({
    required String key,
    required bool hasCompileTimeDefine,
    required bool compileTimeValue,
    bool defaultValue = false,
  }) {
    // 1. Compile-time `--dart-define` always takes top priority
    if (hasCompileTimeDefine) {
      return compileTimeValue;
    }
    // 2. Bundled .env asset (runtime via flutter_dotenv)
    if (dotenv.isInitialized) {
      final envVal = dotenv.maybeGet(key)?.trim();
      if (envVal != null && envVal.isNotEmpty) {
        final lower = envVal.toLowerCase();
        return lower == 'true' || lower == '1';
      }
    }
    // 3. Fallback default
    return defaultValue;
  }

  static String _envString(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.maybeGet(key)?.trim() ?? '';
  }

  static String _normalize(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static void _validateReleaseApiBaseUrl({required String apiBaseUrl}) {
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
