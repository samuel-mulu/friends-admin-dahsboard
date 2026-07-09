import '../../data/models/game_model.dart';
import 'live_presentation_phase.dart';

/// Chooses which game slot/session the inline registration panel should target.
GameModel? resolvePrimaryRegistrationTarget({
  GameModel? currentGame,
  required GameModel? nextUpcomingGame,
  required bool hasCurrentCartelas,
}) {
  // 1) Current PLAYING + owned cartelas => pin to current session.
  if (currentGame != null &&
      currentGame.status == GameStatus.playing &&
      hasCurrentCartelas) {
    return currentGame;
  }

  // 2) Current READY + canRegister => target current session.
  if (currentGame != null &&
      currentGame.status == GameStatus.ready &&
      currentGame.canRegister) {
    return currentGame;
  }

  // 3) No current READY + no owned cartelas => first registerable READY candidate.
  if (!hasCurrentCartelas &&
      nextUpcomingGame != null &&
      nextUpcomingGame.status == GameStatus.ready &&
      nextUpcomingGame.canRegister) {
    return nextUpcomingGame;
  }

  // 4) Otherwise no target.
  return null;
}

bool usesExpandedNoCartelaRegistrationLayout({
  required bool isGuest,
  required bool hasCurrentCartelas,
  required bool showsInlinePlayCartelas,
  required GameModel? registrationTarget,
}) {
  return !isGuest &&
      !hasCurrentCartelas &&
      showsInlinePlayCartelas &&
      registrationTarget != null;
}

bool blocksRegistrationPromotionDuringReview({
  required bool postGameSummaryReviewActive,
  required bool isPresentationReviewPhase,
  required GameStatus? gameStatus,
  required bool winnerWindowExpired,
  required bool isCancelledTerminal,
}) {
  if (isCancelledTerminal) {
    return false;
  }
  if (postGameSummaryReviewActive) {
    return true;
  }
  if (isPresentationReviewPhase) {
    return true;
  }
  if (gameStatus == GameStatus.finished || gameStatus == GameStatus.noWinner) {
    return true;
  }
  if (gameStatus == GameStatus.winnerWindow && winnerWindowExpired) {
    return true;
  }
  return false;
}

/// Next-round registration stays open while the current round is live, but the
/// countdown must not run until that round finishes.
bool shouldDeferNextRoundRegistrationCountdown({
  required LivePresentationPhase currentPhase,
  required bool registrationTargetIsCurrentGame,
}) {
  if (registrationTargetIsCurrentGame) {
    return false;
  }

  return switch (currentPhase) {
    LivePresentationPhase.liveWaitingFirstBall ||
    LivePresentationPhase.liveCalling ||
    LivePresentationPhase.winnerWindow ||
    LivePresentationPhase.winnerWindowClosing ||
    LivePresentationPhase.checking => true,
    _ => false,
  };
}

bool shouldUseMissedRoundRegistrationPresentation({
  required bool registrationTargetIsCurrentGame,
  required bool hasBlockingLiveGame,
  required bool hasCurrentCartelas,
  required GameModel? registrationTarget,
}) {
  return registrationTargetIsCurrentGame &&
      hasBlockingLiveGame &&
      !hasCurrentCartelas &&
      registrationTarget?.status == GameStatus.ready &&
      (registrationTarget?.canRegister ?? false);
}

bool shouldPromoteRegistrationTargetToPrimaryLayout({
  required bool isGuest,
  required bool hasCurrentCartelas,
  required bool currentPhaseIsTerminal,
  required bool blocksRegistrationPromotion,
  required bool registrationTargetIsCurrentGame,
  required GameModel? registrationTarget,
}) {
  return !isGuest &&
      !hasCurrentCartelas &&
      currentPhaseIsTerminal &&
      !blocksRegistrationPromotion &&
      !registrationTargetIsCurrentGame &&
      registrationTarget?.status == GameStatus.ready &&
      (registrationTarget?.canRegister ?? false);
}
