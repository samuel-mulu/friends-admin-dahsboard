import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';

/// Opt-in `[chain]` console tracing for Chain Game round boundaries.
///
/// Enabled in debug builds when `CHAIN_DEBUG=true` or `REALTIME_DEBUG=true`.
class ChainGameDebug {
  ChainGameDebug._();

  static bool get isEnabled =>
      kDebugMode &&
      (AppConfig.fromEnvironment().chainDebug ||
          AppConfig.fromEnvironment().realtimeDebug);

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('chain', message);
  }
}
