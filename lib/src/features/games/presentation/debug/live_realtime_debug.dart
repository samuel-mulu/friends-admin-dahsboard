import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';

/// Opt-in console tracing for AUTO call / live-game sync.
///
/// Set `REALTIME_DEBUG=true` in `.env` and run with:
/// `flutter run -d chrome --dart-define-from-file=.env`
class LiveRealtimeDebug {
  LiveRealtimeDebug._();

  static bool get isEnabled =>
      kDebugMode && AppConfig.fromEnvironment().realtimeDebug;

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', message);
  }

  static void socket(String event, [Map<String, dynamic>? payload]) {
    if (!isEnabled) {
      return;
    }
    if (payload == null || payload.isEmpty) {
      AppLogger.debug('AutoCall', 'socket $event');
      return;
    }

    final summary = _summarizePayload(event, payload);
    AppLogger.debug('AutoCall', 'socket $event $summary');
  }

  static void phase(String from, String to, {String? detail}) {
    if (!isEnabled) {
      return;
    }
    final suffix = detail == null ? '' : ' ($detail)';
    AppLogger.debug('AutoCall', 'phase $from -> $to$suffix');
  }

  static void refetch(String reason, {String? status, int? calledCount}) {
    refreshRequested(reason: reason, status: status, calledCount: calledCount);
  }

  static void refreshRequested({
    required String reason,
    String? status,
    int? calledCount,
    bool terminal = false,
  }) {
    if (!isEnabled) {
      return;
    }
    final parts = <String>[
      'refresh_requested reason=$reason',
      if (terminal) 'terminal=true',
      if (status != null) 'status=$status',
      if (calledCount != null) 'called=$calledCount',
    ];
    AppLogger.debug('AutoCall', parts.join(' '));
  }

  static void refreshStarted({
    required String reason,
    String? status,
    int? calledCount,
    bool includeCalledNumbers = false,
    bool includeMyCartelas = false,
    bool wallet = false,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'refresh_started reason=$reason status=${status ?? '-'} '
          'called=${calledCount ?? '-'} includeCalledNumbers=$includeCalledNumbers '
          'includeMyCartelas=$includeMyCartelas wallet=$wallet',
    );
  }

  static void refreshCoalesced({required String reason}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'refresh_coalesced reason=$reason');
  }

  static void refreshApplied({
    required String reason,
    String? status,
    int? calledCount,
    int? localCalledCount,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'refresh_applied reason=$reason status=${status ?? '-'} '
          'called=${calledCount ?? '-'} localCalled=${localCalledCount ?? '-'}',
    );
  }

  static void refreshFailed({required String reason, required Object error}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'refresh_failed reason=$reason error=$error');
  }

  static void resumeSyncScheduled({
    required String reason,
    required List<String> collectedReasons,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'resume_sync_scheduled reason=$reason collected=${collectedReasons.join('+')}',
    );
  }

  static void resumeSyncIgnored({required String reason}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_sync_ignored reason=$reason');
  }

  static void resumeSyncStarted({required String reason}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_sync_started reason=$reason');
  }

  static void resumeSyncOpsApplied({
    String? primaryStatus,
    String? liveStatus,
    String? registrationStatus,
    String? sessionId,
    int? calledCount,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'resume_sync_ops_applied primary=${primaryStatus ?? '-'} '
          'live=${liveStatus ?? '-'} registration=${registrationStatus ?? '-'} '
          'session=${sessionId ?? '-'} called=${calledCount ?? '-'}',
    );
  }

  static void resumeSyncMyCartelasLoaded({required int count}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_sync_cartelas_loaded count=$count');
  }

  static void resumeSyncWalletLoaded() {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_sync_wallet_loaded');
  }

  static void resumeSyncCalledNumbersLoaded({required int count}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'resume_sync_called_numbers_loaded count=$count',
    );
  }

  static void resumeSyncCompleted({
    required String reason,
    String? primaryStatus,
    String? liveStatus,
    String? registrationStatus,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'resume_sync_completed reason=$reason primary=${primaryStatus ?? '-'} '
          'live=${liveStatus ?? '-'} registration=${registrationStatus ?? '-'}',
    );
  }

  static void resumeSyncFailed({required String reason, required Object error}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_sync_failed reason=$reason error=$error');
  }

  static void providerInvalidated({
    required String provider,
    required String reason,
    String? sessionId,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'provider_invalidated provider=$provider reason=$reason '
          'session=${sessionId ?? '-'}',
    );
  }

  static void providerInvalidateSkipped({
    required String provider,
    required String reason,
    String? sessionId,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'provider_invalidate_skipped provider=$provider reason=$reason '
          'session=${sessionId ?? '-'}',
    );
  }

  static void resumeFetchSkipped({
    required String type,
    required String reason,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'AutoCall',
      'resume_fetch_skipped type=$type reason=$reason',
    );
  }

  static void resumeCacheHit({required String type}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_cache_hit type=$type');
  }

  static void resumeCacheMiss({required String type}) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('AutoCall', 'resume_cache_miss type=$type');
  }

  static void apiFailure({
    required String method,
    required String endpoint,
    String? sessionId,
    int? statusCode,
    required String message,
    Object? responseBody,
    Object? requestPayload,
  }) {
    if (!kDebugMode) {
      return;
    }
    AppLogger.debug(
      'LiveApi',
      '$method $endpoint status=${statusCode ?? '-'} '
          'session=${_maskId(sessionId)} message=$message '
          'payload=$requestPayload body=$responseBody',
    );
  }

  static int? _lastCountdownRemaining;
  static DateTime? _lastCountdownTarget;

  static void resetCountdownDedup() {
    _lastCountdownRemaining = null;
    _lastCountdownTarget = null;
  }

  static void countdown({
    required DateTime? target,
    required DateTime? serverNow,
    required DateTime deviceNow,
    required int? offsetMs,
    required int remaining,
  }) {
    if (!isEnabled) {
      return;
    }

    if (_lastCountdownRemaining == remaining && _lastCountdownTarget == target) {
      return;
    }

    _lastCountdownRemaining = remaining;
    _lastCountdownTarget = target;

    AppLogger.debug(
      'Countdown',
      'target=$target serverNow=$serverNow '
          'deviceNow=$deviceNow offsetMs=$offsetMs remaining=$remaining',
    );
  }

  static void countdownStale({
    required String phase,
    required String? sessionId,
    required DateTime? target,
    required int zeroForMs,
    required String recovery,
  }) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug(
      'CountdownStale',
      'phase=$phase session=${_maskId(sessionId)} '
          'target=$target zeroForMs=$zeroForMs recovery=$recovery',
    );
  }

  static String _summarizePayload(String event, Map<String, dynamic> payload) {
    switch (event) {
      case 'game:number_called':
        return _numberCalledSummary(payload);
      case 'game:status_changed':
        return _statusChangedSummary(payload);
      case 'game:operation_updated':
        return _operationUpdatedSummary(payload);
      default:
        final sessionId = payload['sessionId'] as String?;
        final slotId = payload['slotId'] as String? ?? payload['gameSlotId'];
        return 'session=${_maskId(sessionId)} slot=${_maskId(slotId)}';
    }
  }

  static String _numberCalledSummary(Map<String, dynamic> payload) {
    final order = payload['order'];
    final letter = payload['letter'];
    final number = payload['number'];
    final nextAt = payload['nextAutoCallAt'];
    return 'draw #$order $letter$number nextAutoCallAt=$nextAt';
  }

  static String _statusChangedSummary(Map<String, dynamic> payload) {
    final status = payload['status'];
    final sessionId = payload['sessionId'] ?? payload['id'];
    return 'session=${_maskId(sessionId?.toString())} status=$status';
  }

  static String _operationUpdatedSummary(Map<String, dynamic> payload) {
    final reason = payload['updatedReason'] ?? payload['reason'];
    final enabled = payload['autoCallEnabled'];
    final nextAt = payload['nextAutoCallAt'];
    final intervalMs = payload['autoCallIntervalMs'];
    return 'reason=$reason autoCallEnabled=$enabled '
        'intervalMs=$intervalMs nextAutoCallAt=$nextAt';
  }

  static String _maskId(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return AppLogger.shortIdentifier(value);
  }
}
