import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';

/// Registration target eligibility for embedded Big Game (banner/body alignment).
bool bigGameRegistrationEligible(GameModel game, DateTime now) {
  if (!game.isBigGame) {
    return false;
  }
  if (game.canRegister) {
    return true;
  }
  return isBigGameRegistrationWindowOpen(game, now: now);
}

/// Standard games use [GameModel.canRegister]; embedded Big Game uses [bigGameRegistrationEligible].
bool liveRegistrationEligible({
  required GameModel game,
  required DateTime now,
  required bool embeddedBigGame,
}) {
  if (embeddedBigGame && game.isBigGame) {
    return bigGameRegistrationEligible(game, now);
  }
  return game.canRegister;
}

/// Avoid flashing "No registered cartelas" while private state catches up.
bool shouldSuppressEmbeddedBigGameEmptyCartelaState({
  required bool embeddedBigGame,
  required bool isGuest,
  required bool hasPrimarySessionCartelas,
  required bool initialLoadComplete,
  required bool isLoading,
  required bool resumeSyncInFlight,
  required bool canonicalRefetchInFlight,
}) {
  if (!embeddedBigGame || isGuest || hasPrimarySessionCartelas) {
    return false;
  }
  if (initialLoadComplete &&
      !isLoading &&
      !resumeSyncInFlight &&
      !canonicalRefetchInFlight) {
    return false;
  }
  return true;
}

/// More rounds in the slot after this session ends (or next session already linked).
bool bigGameSlotHasMoreRoundsAfterTerminal(GameModel terminalGame) {
  if (!terminalGame.isBigGame) {
    return false;
  }
  final roundCount = terminalGame.roundCount ?? 1;
  if (terminalGame.displayRoundIndex < roundCount) {
    return true;
  }
  if (terminalGame.nextRoundRegistration != null) {
    return true;
  }
  if (terminalGame.nextRoundStartsAt != null) {
    return true;
  }
  return false;
}

/// Next READY session for embedded Big Game (ops queue + card handoff).
GameModel? resolveEmbeddedBigGameAdvanceTarget({
  required GameModel terminalGame,
  required GameOperationsCurrentResponse? operations,
  required DateTime now,
}) {
  if (!terminalGame.isBigGame) {
    return null;
  }

  final fromOps = operations?.resolveAdvanceTargetFor(
    terminalGame: terminalGame,
  );
  if (fromOps != null &&
      fromOps.status == GameStatus.ready &&
      liveRegistrationEligible(
        game: fromOps,
        now: now,
        embeddedBigGame: true,
      )) {
    return fromOps;
  }

  final cardNext = terminalGame.nextRoundRegistration;
  if (cardNext != null &&
      cardNext.sessionId != null &&
      cardNext.sessionId != terminalGame.sessionId &&
      cardNext.status == GameStatus.ready &&
      liveRegistrationEligible(
        game: cardNext,
        now: now,
        embeddedBigGame: true,
      )) {
    return cardNext;
  }

  return null;
}

/// Whether embedded live should stay mounted for the 60s terminal summary.
bool shouldEmbedBigGameTerminalReviewHost({
  required GameModel game,
  required BigGamePhase phase,
}) {
  if (phase != BigGamePhase.finishedReview) {
    return false;
  }
  return game.isBigGame &&
      (game.status == GameStatus.finished ||
          game.status == GameStatus.noWinner);
}
