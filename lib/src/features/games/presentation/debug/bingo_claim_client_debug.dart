import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';

/// Opt-in `[bingo_claim_client]` tracing for claim latency / recovery.
class BingoClaimClientDebug {
  BingoClaimClientDebug._();

  static bool get isEnabled =>
      kDebugMode && AppConfig.fromEnvironment().realtimeDebug;

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('bingo_claim_client', message);
  }
}
