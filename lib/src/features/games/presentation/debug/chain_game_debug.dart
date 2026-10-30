import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';

/// Chain Game console tracing. Always on in debug builds; optional extra via
/// `CHAIN_DEBUG` / `REALTIME_DEBUG` in `.env` (no `.env` required).
class ChainGameDebug {
  ChainGameDebug._();

  static bool get isEnabled {
    if (!kDebugMode) {
      return false;
    }
    try {
      final config = AppConfig.fromEnvironment();
      if (config.chainDebug || config.realtimeDebug) {
        return true;
      }
    } catch (_) {
      // Dotenv unset — still trace in debug builds.
    }
    return true;
  }

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('chain', message);
  }
}
