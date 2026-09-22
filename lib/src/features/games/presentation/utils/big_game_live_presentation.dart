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

/// Merges [nextRoundRegistration] from prefetch/card seed onto a pinned FINISHED
/// round so advance + summary handoff see Round N+1 when ops lag.
GameModel mergeEmbeddedBigGameTerminalHandoff({
  required GameModel terminalGame,
  GameModel? queuedUpcoming,
  GameModel? cardSeed,
}) {
  if (!terminalGame.isBigGame || terminalGame.nextRoundRegistration != null) {
    return terminalGame;
  }

  final fromCard = cardSeed?.nextRoundRegistration;
  if (fromCard != null &&
      fromCard.sessionId != null &&
      fromCard.sessionId != terminalGame.sessionId) {
    return terminalGame.copyWith(nextRoundRegistration: fromCard);
  }

  if (queuedUpcoming != null &&
      queuedUpcoming.sessionId != null &&
      queuedUpcoming.sessionId != terminalGame.sessionId) {
    return terminalGame.copyWith(nextRoundRegistration: queuedUpcoming);
  }

  return terminalGame;
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

/// Whether embedded live should stay mounted for the 60s terminal summary.
bool shouldEmbedBigGameTerminalReviewHost({
  required GameModel game,
  required BigGamePhase phase,
}) {
  if (!game.isBigGame) {
    return false;
  }
  return phase == BigGamePhase.finishedReview &&
      (game.status == GameStatus.finished ||
          game.status == GameStatus.noWinner);
}
