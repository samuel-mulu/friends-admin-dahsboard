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

/// Backend operational primary may already be Round N+1 READY after Round N
/// finishes. Flutter still needs Round N as the temporary presentation primary
/// so the shared Normal finish machine can pin the finished summary.
///
/// Returns a local seed: Round N FINISHED/NO_WINNER with
/// [GameModel.nextRoundRegistration] = Round N+1. Does not change backend.
GameModel resolveBigGamePresentationSeed(GameModel operationalPrimary) {
  if (!operationalPrimary.isBigGame) {
    return operationalPrimary;
  }

  switch (operationalPrimary.status) {
    case GameStatus.finished:
    case GameStatus.noWinner:
    case GameStatus.playing:
    case GameStatus.checking:
    case GameStatus.winnerWindow:
    case GameStatus.cancelled:
      return operationalPrimary;
    case GameStatus.ready:
    case GameStatus.next:
      break;
  }

  final previous = operationalPrimary.previousRound;
  if (previous == null) {
    return operationalPrimary;
  }
  if (previous.status != GameStatus.finished &&
      previous.status != GameStatus.noWinner) {
    return operationalPrimary;
  }
  if (previous.roundIndex + 1 != operationalPrimary.displayRoundIndex) {
    return operationalPrimary;
  }

  return buildBigGamePinnedTerminalSeed(
    operationalNext: operationalPrimary,
    previous: previous,
  );
}

/// Builds a Round-N terminal [GameModel] for Live summary pin from the
/// operational Round-N+1 card + [previousRound] summary.
GameModel buildBigGamePinnedTerminalSeed({
  required GameModel operationalNext,
  required BigGamePreviousRoundSummary previous,
}) {
  final nextAsSecondary = operationalNext.copyWith(
    previousRound: null,
  );

  return GameModel(
    id: operationalNext.id,
    sessionId: previous.sessionId,
    staticCode: operationalNext.staticCode,
    playCode: previous.playCode ?? operationalNext.playCode,
    name: operationalNext.name,
    gameRule: operationalNext.gameRule,
    gameType: operationalNext.gameType,
    entryFee: operationalNext.entryFee,
    prizePerCartela: operationalNext.prizePerCartela,
    companyFeePerCartela: operationalNext.companyFeePerCartela,
    prizeAmount: operationalNext.prizeAmount,
    companyRevenue: operationalNext.companyRevenue,
    status: previous.status,
    playOrder: operationalNext.playOrder,
    startedAt: operationalNext.startedAt,
    finishedAt: previous.finishedAt,
    createdAt: operationalNext.createdAt,
    updatedAt: previous.finishedAt ?? operationalNext.updatedAt,
    registeredCartelasCount: previous.registeredCartelasCount,
    calledNumbersCount: operationalNext.calledNumbersCount,
    registrationOpen: false,
    canRegister: false,
    scheduledStartAt: null,
    registrationOpensAt: null,
    operationMode: operationalNext.operationMode,
    category: GameCategory.bigGame,
    fixedPrizeAmount: operationalNext.fixedPrizeAmount,
    maxCartelasPerPlayer: operationalNext.maxCartelasPerPlayer,
    roundCount: operationalNext.roundCount,
    currentRound: previous.roundIndex,
    roundIndex: previous.roundIndex,
    roundPrizes: operationalNext.roundPrizes,
    roundPrizeAmount: operationalNext.roundPrizeAmount,
    nextRoundStartsAt:
        operationalNext.scheduledStartAt ?? operationalNext.nextRoundStartsAt,
    bigGameTicketBalance: operationalNext.bigGameTicketBalance,
    finishedRounds: operationalNext.finishedRounds,
    nextRoundRegistration: nextAsSecondary,
  );
}

/// True when [incoming] is the same-slot next round after the mounted Round N
/// (used so BigGameLiveHost does not remount away from a pinned summary).
///
/// Matches via [previousRound.sessionId] when present (READY N+1), or via
/// slot + roundIndex == mounted.roundIndex + 1 when previousRound is absent
/// (e.g. N+1 already PLAYING).
bool isBigGameIncomingNextRoundAfterMounted({
  required GameModel incoming,
  required String? mountedSessionId,
  GameModel? mountedGame,
}) {
  if (!incoming.isBigGame ||
      mountedSessionId == null ||
      mountedSessionId.isEmpty) {
    return false;
  }
  if (incoming.previousRound?.sessionId == mountedSessionId) {
    return true;
  }
  final mounted = mountedGame;
  if (mounted == null || !mounted.isBigGame) {
    return false;
  }
  final mountedTerminal = mounted.status == GameStatus.finished ||
      mounted.status == GameStatus.noWinner;
  if (!mountedTerminal) {
    return false;
  }
  if (incoming.id != mounted.id) {
    return false;
  }
  if (incoming.sessionId == null ||
      incoming.sessionId == mountedSessionId) {
    return false;
  }
  return incoming.displayRoundIndex == mounted.displayRoundIndex + 1;
}

/// Stable shell key for live + finished review so PLAYING → FINISHED does not
/// remount [BigGameLiveHost] and tear down the shared 60s summary.
String bigGameLiveHostInstanceKey(GameModel game) {
  return 'big-game-live-host-${game.id}';
}

/// Nested [LiveGameScreen] key — session only. Do not encode terminal /
/// nextRoundRegistration / missed flags or finish→next READY remounts mid-summary.
String bigGameEmbeddedLiveInstanceKey(String sessionId) {
  return 'big-game-embedded-live-$sessionId';
}

/// Shell chrome during finished review duplicates Live's [RoundFinishedBanner].
/// Live owns finish → next READY; keep the collapsible banner only while live.
bool shouldShowBigGameShellBanner({
  required BigGamePhase phase,
  required bool embedTerminalReview,
}) {
  if (embedTerminalReview || phase == BigGamePhase.finishedReview) {
    return false;
  }
  return phase == BigGamePhase.live ||
      phase == BigGamePhase.registrationOpen ||
      phase == BigGamePhase.beforeRegistrationOpens ||
      phase == BigGamePhase.waitingToPlay;
}

/// Resolves the expected next Big Game round — same slot, roundIndex + 1 —
/// from the live operations snapshot. Checks liveGame, checkingGame,
/// registrationOpenGame, then queue: whichever bucket currently holds the
/// expected round. Verifying slot identity + round sequence here means an
/// unrelated live/queued session is never mistaken for the next Big Game
/// round. Returns null if the next round cannot yet be identified.
GameModel? resolveNextBigGameRound({
  required GameOperationsCurrentResponse? operations,
  required GameModel terminalRound,
}) {
  if (operations == null || !terminalRound.isBigGame) {
    return null;
  }
  final expectedRoundIndex = terminalRound.displayRoundIndex + 1;

  bool isExpectedNextRound(GameModel? candidate) {
    if (candidate == null || !candidate.isBigGame) {
      return false;
    }
    if (candidate.id != terminalRound.id) {
      return false;
    }
    if (candidate.sessionId != null &&
        candidate.sessionId == terminalRound.sessionId) {
      return false;
    }
    return candidate.displayRoundIndex == expectedRoundIndex;
  }

  final candidates = [
    operations.liveGame,
    operations.checkingGame,
    operations.registrationOpenGame,
    ...operations.queue,
  ];
  for (final candidate in candidates) {
    if (isExpectedNextRound(candidate)) {
      return candidate;
    }
  }
  return null;
}

/// Big Game next-round statuses safe to adopt immediately without waiting:
/// READY (countdown/registration) and already-live (PLAYING/CHECKING/
/// WINNER_WINDOW — switch straight to live, do not wait for READY). Backend
/// remains the only owner of READY -> PLAYING; this never mutates status.
bool isBigGameNextRoundAdoptable(GameModel candidate) {
  return switch (candidate.status) {
    GameStatus.ready ||
    GameStatus.next ||
    GameStatus.playing ||
    GameStatus.checking ||
    GameStatus.winnerWindow => true,
    _ => false,
  };
}
