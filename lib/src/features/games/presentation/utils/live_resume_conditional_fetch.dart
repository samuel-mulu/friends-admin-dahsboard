import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import '../../domain/backend_called_number_identity.dart';

import 'live_resume_sync.dart';

typedef ResumeFetchDecision = ({bool shouldFetch, String reason});

bool localCalledNumbersStripMatchesBackend({
  required List<CalledNumberModel> localCalledNumbers,
  required int backendCalledNumbersCount,
  BackendCalledNumberIdentity? backendLatestCalledNumber,
}) {
  if (backendCalledNumbersCount == 0) {
    return localCalledNumbers.isEmpty;
  }

  if (localCalledNumbers.length != backendCalledNumbersCount) {
    return false;
  }

  final localLast = localCalledNumbers.last;
  if (localLast.order != backendCalledNumbersCount) {
    return false;
  }

  if (backendLatestCalledNumber == null) {
    return true;
  }

  return backendLatestCalledNumber.order == localLast.order &&
      backendLatestCalledNumber.letter == localLast.letter &&
      backendLatestCalledNumber.number == localLast.number;
}

ResumeFetchDecision resolveResumeCalledNumbersFetch({
  required GameModel game,
  required String? priorSessionId,
  required List<CalledNumberModel> localCalledNumbers,
  required bool reconnectGapDetected,
}) {
  if (!shouldFetchCalledNumbersForResume(game)) {
    return (shouldFetch: false, reason: 'status_not_live');
  }

  final sessionId = game.sessionId;
  if (sessionId == null ||
      priorSessionId == null ||
      sessionId != priorSessionId) {
    return (shouldFetch: true, reason: 'session_changed');
  }

  if (game.status == GameStatus.finished ||
      game.status == GameStatus.noWinner) {
    return (shouldFetch: true, reason: 'terminal_review');
  }

  if (reconnectGapDetected) {
    return (shouldFetch: true, reason: 'reconnect_gap');
  }

  final backendCount = game.calledNumbersCount;
  if (backendCount > localCalledNumbers.length) {
    return (shouldFetch: true, reason: 'backend_ahead');
  }

  if (localCalledNumbers.isEmpty && backendCount > 0) {
    return (shouldFetch: true, reason: 'local_empty');
  }

  if (localCalledNumbersStripMatchesBackend(
    localCalledNumbers: localCalledNumbers,
    backendCalledNumbersCount: backendCount,
    backendLatestCalledNumber: game.latestCalledNumberIdentity,
  )) {
    return (shouldFetch: false, reason: 'same_count');
  }

  return (shouldFetch: true, reason: 'strip_mismatch');
}

ResumeFetchDecision resolveResumeMyCartelasFetch({
  required GameModel game,
  required String? priorSessionId,
  required int localMyCartelasCount,
  required bool sessionChanged,
}) {
  if (sessionChanged) {
    return (shouldFetch: true, reason: 'session_changed');
  }

  final sessionId = game.sessionId;
  if (sessionId == null || priorSessionId == null) {
    return (shouldFetch: true, reason: 'ownership_unknown');
  }

  if (sessionId != priorSessionId) {
    return (shouldFetch: true, reason: 'session_changed');
  }

  if (game.status == GameStatus.ready) {
    return (shouldFetch: true, reason: 'ready_registration');
  }

  if (game.status == GameStatus.playing && localMyCartelasCount == 0) {
    return (shouldFetch: true, reason: 'playing_empty');
  }

  if (localMyCartelasCount > 0) {
    return (shouldFetch: false, reason: 'same_session_loaded');
  }

  return (shouldFetch: true, reason: 'ownership_unknown');
}
