enum LiveSyncTrigger {
  appResume,
  socketReconnect,
  manualRefresh,
  operationUpdated,
  statusChanged,
  gameCancelled,
  gameFinished,
  walletUpdated,
  staleCountdown,
  invalidPayload,
  numberCalledGap,
  numberCalledConflict,
  bingoValid,
  winnerWindow,
  bingoInvalidMissingSchedule,
  registrationClosedEmpty,
  preparingPoll,
}

enum LiveSyncAction {
  localPatchOnly,
  calledNumbersFetchOnly,
  canonicalSnapshotFetch,
  terminalTransitionSnapshot,
  ignore,
}

LiveSyncAction resolveLiveSyncTriggerAction(
  LiveSyncTrigger trigger, {
  String? updatedReason,
  bool isTerminalStatus = false,
  bool terminalTransitionActive = false,
  int staleStage = 1,
}) {
  switch (trigger) {
    case LiveSyncTrigger.appResume:
    case LiveSyncTrigger.socketReconnect:
      if (terminalTransitionActive) {
        return LiveSyncAction.ignore;
      }
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.manualRefresh:
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.operationUpdated:
      if (updatedReason == 'number_called') {
        return LiveSyncAction.ignore;
      }
      if (updatedReason == 'auto_call_changed') {
        return LiveSyncAction.localPatchOnly;
      }
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.statusChanged:
      return isTerminalStatus
          ? LiveSyncAction.terminalTransitionSnapshot
          : LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.gameCancelled:
    case LiveSyncTrigger.gameFinished:
      return LiveSyncAction.terminalTransitionSnapshot;
    case LiveSyncTrigger.walletUpdated:
      return LiveSyncAction.ignore;
    case LiveSyncTrigger.staleCountdown:
      return staleStage <= 1
          ? LiveSyncAction.calledNumbersFetchOnly
          : LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.invalidPayload:
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.numberCalledGap:
      return LiveSyncAction.calledNumbersFetchOnly;
    case LiveSyncTrigger.numberCalledConflict:
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.bingoValid:
    case LiveSyncTrigger.winnerWindow:
      return LiveSyncAction.localPatchOnly;
    case LiveSyncTrigger.bingoInvalidMissingSchedule:
    case LiveSyncTrigger.registrationClosedEmpty:
    case LiveSyncTrigger.preparingPoll:
      return LiveSyncAction.canonicalSnapshotFetch;
  }
}
