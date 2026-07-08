import 'live_sync_trigger_action.dart';

LiveSyncTrigger liveSyncTriggerFromResumeReason(String reason) {
  final normalized = reason.toLowerCase();
  if (normalized.contains('manual_refresh')) {
    return LiveSyncTrigger.manualRefresh;
  }
  if (normalized.contains('socket_reconnect') ||
      normalized.contains('reconnect')) {
    return LiveSyncTrigger.socketReconnect;
  }
  return LiveSyncTrigger.appResume;
}

bool shouldRunResumeSync({
  required LiveSyncTrigger trigger,
  required bool postGameSummaryReviewActive,
  required bool postGameSummaryAdvancing,
  required bool terminalCanonicalRefetchInFlight,
}) {
  final terminalActive = postGameSummaryReviewActive ||
      postGameSummaryAdvancing ||
      terminalCanonicalRefetchInFlight;

  // manual_refresh, app_resume and socket_reconnect all resolve through the
  // single trigger table. During an active terminal transition every one of
  // them (including manual_refresh) resolves to `ignore` so nothing races the
  // atomic terminal apply. Outside a terminal transition manual_refresh always
  // runs a canonical snapshot fetch.
  final action = resolveLiveSyncTriggerAction(
    trigger,
    terminalTransitionActive: terminalActive,
  );
  return action != LiveSyncAction.ignore;
}

bool isTerminalCanonicalRefetchActive({
  required bool canonicalRefetchInFlight,
  required String? pendingRefetchReason,
  required DateTime? lastTerminalCanonicalRefetchRequestedAt,
  required DateTime now,
}) {
  if (!canonicalRefetchInFlight &&
      lastTerminalCanonicalRefetchRequestedAt == null) {
    return false;
  }

  final reason = pendingRefetchReason ?? '';
  final reasonLooksTerminal = reason.startsWith('game_') ||
      reason.contains('terminal') ||
      reason.contains('status_changed_terminal') ||
      reason == 'game_cancelled' ||
      reason == 'game_finished';

  final recentlyRequested = lastTerminalCanonicalRefetchRequestedAt != null &&
      now.difference(lastTerminalCanonicalRefetchRequestedAt!) <
          const Duration(seconds: 3);

  return (canonicalRefetchInFlight && reasonLooksTerminal) || recentlyRequested;
}
