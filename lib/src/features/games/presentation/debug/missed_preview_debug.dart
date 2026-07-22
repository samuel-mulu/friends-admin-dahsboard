import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';
import '../utils/missed_live_preview_resolver.dart';

/// Console tracing for the missed-player read-only live preview.
///
/// Logs in debug builds when [realtimeDebug] is enabled, or always in debug
/// when [alwaysLogInDebug] is true (default).
class MissedPreviewDebug {
  MissedPreviewDebug._();

  static bool get isEnabled =>
      kDebugMode &&
      (AppConfig.fromEnvironment().realtimeDebug || alwaysLogInDebug);

  /// When true, missed-preview logs appear in any debug run without `.env`.
  static const bool alwaysLogInDebug = true;

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('MissedPreview', message);
  }

  static void foreignEvent({
    required String event,
    required String? eventSessionId,
    required String? primarySessionId,
    required bool willSync,
  }) {
    log(
      'foreign_event event=$event session=${eventSessionId ?? '-'} '
      'primary=${primarySessionId ?? '-'} sync=$willSync',
    );
  }

  static void numberApplied({
    required int order,
    required String sessionId,
    required int previewBallCount,
    int? remaining,
  }) {
    log(
      'number_applied order=$order session=$sessionId '
      'previewBalls=$previewBallCount '
      '${remaining != null ? 'remaining=$remaining' : ''}',
    );
  }

  static void syncScheduled({required String reason}) {
    log('sync_scheduled reason=$reason');
  }

  static void resolution({
    required MissedLivePreviewResolution resolution,
    required int previewBallCount,
    int? remaining,
  }) {
    log(
      'resolution show=${resolution.showPreview} '
      'phase=${resolution.phase.name} '
      'session=${resolution.previewSession?.sessionId ?? '-'} '
      'previewBalls=$previewBallCount '
      '${remaining != null ? 'remaining=$remaining' : ''}',
    );
  }
}
