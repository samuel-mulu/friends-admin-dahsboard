import '../../data/models/game_model.dart';
import 'live_presentation_phase.dart';

/// Which end-of-round UX owns the screen — never show two at once.
enum LiveRoundBreakOwner {
  none,
  chainInterRound,
  postGameTerminal,
}

bool chainRoundPauseActiveForBreak({
  required GameModel? game,
  required DateTime now,
  DateTime? latchedPausedUntil,
  bool canonicalRefetchInFlight = false,
}) {
  if (game != null && isChainRoundPauseActive(game, now: now)) {
    return true;
  }
  if (!canonicalRefetchInFlight || latchedPausedUntil == null) {
    return false;
  }
  return now.isBefore(latchedPausedUntil);
}

/// Chain mid-draw break: PLAYING + pause, and the round that just finished is
/// not the final round of the chain (`roundIndex` already points at next round).
bool chainInterRoundBreakEligible(
  GameModel? game, {
  required DateTime now,
  DateTime? latchedPausedUntil,
  bool canonicalRefetchInFlight = false,
}) {
  if (game == null || !game.isChainGame) {
    return false;
  }
  if (game.status != GameStatus.playing) {
    return false;
  }
  if (!chainRoundPauseActiveForBreak(
    game: game,
    now: now,
    latchedPausedUntil: latchedPausedUntil,
    canonicalRefetchInFlight: canonicalRefetchInFlight,
  )) {
    return false;
  }
  final finishedRound = chainRevealedRoundIndex(game, now: now);
  if (finishedRound >= game.displayRoundCount) {
    return false;
  }
  final finalChainRoundDecided = game.roundResults.any(
    (round) =>
        round.roundIndex == game.displayRoundCount && round.winners.isNotEmpty,
  );
  if (finalChainRoundDecided) {
    return false;
  }
  return true;
}

LiveRoundBreakOwner resolveLiveRoundBreakOwner({
  required GameModel? game,
  required bool postGameSummaryReviewActive,
  required bool chainInterRoundSummaryActive,
  required bool chainInterRoundSummaryDismissed,
  required DateTime now,
  DateTime? latchedChainPausedUntil,
  bool canonicalRefetchInFlight = false,
}) {
  if (game == null) {
    return LiveRoundBreakOwner.none;
  }

  final terminalStatus =
      game.status == GameStatus.finished ||
      game.status == GameStatus.noWinner;
  if (postGameSummaryReviewActive && terminalStatus) {
    return LiveRoundBreakOwner.postGameTerminal;
  }

  if (chainInterRoundSummaryActive &&
      !chainInterRoundSummaryDismissed &&
      chainInterRoundBreakEligible(
        game,
        now: now,
        latchedPausedUntil: latchedChainPausedUntil,
        canonicalRefetchInFlight: canonicalRefetchInFlight,
      )) {
    return LiveRoundBreakOwner.chainInterRound;
  }

  return LiveRoundBreakOwner.none;
}

/// Embedded Big Game: skip auto winner modal between slot rounds so the 60s
/// finished summary + Continue hand off cleanly to the next registration window.
bool shouldSuppressBigGameAutoWinnerModalBetweenRounds({
  required GameModel? game,
  required bool embeddedBigGame,
  required bool postGameSummaryReviewActive,
}) {
  if (!embeddedBigGame || game == null || !game.isBigGame) {
    return false;
  }
  if (!postGameSummaryReviewActive) {
    return false;
  }
  final roundCount = game.roundCount ?? 1;
  if (roundCount <= 1) {
    return false;
  }
  final roundIndex = game.displayRoundIndex;
  return roundIndex < roundCount;
}
