import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import '../../data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';
import 'chain_round_cartela_state.dart';
import 'live_presentation_phase.dart';

/// Why an AUTO-queued cartela cannot submit right now.
enum AutoBingoBlockKind {
  /// Ready to submit.
  none,

  /// Keep in queue; resume when claim lifecycle / strip / lock clears.
  temporary,

  /// Drop from queue; do not retry until a new session/round context.
  permanent,
}

/// Attempt-level dedupe: one AUTO attempt identity per completing ball.
String autoBingoAttemptDedupeKey({
  required String sessionId,
  required int roundIndex,
  required String gameCartelaId,
  required int completingCalledOrder,
}) =>
    '$sessionId|$roundIndex|$gameCartelaId|$completingCalledOrder';

/// Terminal suppression: no further AUTO for this cartela in the session/round.
String autoBingoTerminalSuppressKey({
  required String sessionId,
  required int roundIndex,
  required String gameCartelaId,
}) =>
    '$sessionId|$roundIndex|$gameCartelaId';

int completingCalledOrderOf(List<CalledNumberModel> calledNumbers) {
  if (calledNumbers.isEmpty) {
    return 0;
  }
  var maxOrder = calledNumbers.first.order;
  for (final call in calledNumbers) {
    if (call.order > maxOrder) {
      maxOrder = call.order;
    }
  }
  return maxOrder;
}

/// Chain AUTO must mirror manual: no round N+1 claim until a new ball is committed.
bool isChainAutoBingoClaimAllowed({
  required GameModel? game,
  required int calledNumbersCount,
  required int? chainBingoArmedAfterCalledCount,
  DateTime? now,
}) {
  if (game == null || !game.isChainGame) {
    return true;
  }
  if (isChainRoundPauseActive(game, now: now)) {
    return false;
  }
  final needsArmSnapshot =
      game.displayRoundIndex > 1 || hasAuthoritativeChainRoundAdvance(game);
  if (needsArmSnapshot && chainBingoArmedAfterCalledCount == null) {
    return false;
  }
  return isChainBingoArmedAfterNewBall(
    game: game,
    calledNumbersCount: calledNumbersCount,
    armedAfterCalledCount: chainBingoArmedAfterCalledCount,
  );
}

/// Round 2+ AUTO cannot use the pre-arm max order (e.g. round-1 winning ball).
bool isChainAutoBingoCompletingBallFresh({
  required int completingCalledOrder,
  required int? chainBingoArmedAfterCalledCount,
}) {
  if (chainBingoArmedAfterCalledCount == null) {
    return true;
  }
  return completingCalledOrder > chainBingoArmedAfterCalledCount;
}

/// Local scheduling only — Nest remains claim authority.
/// Evaluates with [calledNumberMarkKeys], never manual/visual marks.
List<GameCartelaModel> selectAutoBingoPatternCompleteCartelas({
  required Iterable<GameCartelaModel> cartelas,
  required List<CalledNumberModel> calledNumbers,
  required String ruleKey,
  required Set<String> terminalSuppressKeys,
  required Set<String> attemptDedupeKeys,
  required String sessionId,
  required int roundIndex,
  required int completingCalledOrder,
  GameModel? chainGateGame,
  int calledNumbersCount = 0,
  int? chainBingoArmedAfterCalledCount,
  DateTime? chainGateNow,
}) {
  if (calledNumbers.isEmpty || completingCalledOrder <= 0) {
    return const [];
  }

  if (chainGateGame != null &&
      !isChainAutoBingoClaimAllowed(
        game: chainGateGame,
        calledNumbersCount: calledNumbersCount,
        chainBingoArmedAfterCalledCount: chainBingoArmedAfterCalledCount,
        now: chainGateNow,
      )) {
    return const [];
  }

  final calledKeys = calledNumberMarkKeys(calledNumbers);
  final eligible = <GameCartelaModel>[];

  for (final cartela in cartelas) {
    if (cartela.status != GameCartelaStatus.registered) {
      continue;
    }
    final suppressKey = autoBingoTerminalSuppressKey(
      sessionId: sessionId,
      roundIndex: roundIndex,
      gameCartelaId: cartela.id,
    );
    if (terminalSuppressKeys.contains(suppressKey)) {
      continue;
    }
    final attemptKey = autoBingoAttemptDedupeKey(
      sessionId: sessionId,
      roundIndex: roundIndex,
      gameCartelaId: cartela.id,
      completingCalledOrder: completingCalledOrder,
    );
    if (attemptDedupeKeys.contains(attemptKey)) {
      continue;
    }

    final result = CartelaMarkedPatternEvaluator.evaluate(
      cartela: cartela,
      manualMarkedNumbers: calledKeys,
      ruleKey: ruleKey,
    );
    if (!result.hasLocalPatternComplete) {
      continue;
    }
    if (!isChainAutoBingoCompletingBallFresh(
      completingCalledOrder: completingCalledOrder,
      chainBingoArmedAfterCalledCount: chainBingoArmedAfterCalledCount,
    )) {
      continue;
    }
    eligible.add(cartela);
  }

  eligible.sort((a, b) {
    final byNumber = a.cartela.number.compareTo(b.cartela.number);
    if (byNumber != 0) {
      return byNumber;
    }
    return a.id.compareTo(b.id);
  });
  return eligible;
}

/// Merge newly detected cartela ids into [queue] without duplicates.
List<String> enqueueAutoBingoCartelas({
  required List<String> queue,
  required Iterable<String> incomingIds,
}) {
  final next = List<String>.from(queue);
  final seen = next.toSet();
  for (final id in incomingIds) {
    if (seen.add(id)) {
      next.add(id);
    }
  }
  return next;
}

bool gameAllowsAutoBingoClaims(GameModel? game) {
  if (game == null) {
    return false;
  }
  if (!game.isAutomaticRule) {
    return false;
  }
  return game.status == GameStatus.playing ||
      game.status == GameStatus.winnerWindow;
}

/// Expected AUTO business rejection codes that may stay quiet in UI.
bool isQuietAutoBingoFailureCode(String? failureCode) {
  return failureCode == 'AUTO_BINGO_NOT_ALLOWED';
}

/// Classify the queue head before AUTO submit (R1).
AutoBingoBlockKind classifyAutoBingoQueueHead({
  required bool effectiveAutoBingo,
  required bool gameAllowsClaims,
  required bool winnerWindowExpired,
  required GameCartelaModel? cartela,
  required bool sessionRoundMatches,
  required bool isConfirmingOrClaimingAny,
  required bool claimStripHoldActive,
  required bool hasUnresolvedAttemptForCartela,
  required bool bingoClaimLocked,
  required bool claimScopeLoading,
  required bool autoSubmitInFlight,
  required bool terminalSuppressed,
  GameModel? chainGateGame,
  int calledNumbersCount = 0,
  int? chainBingoArmedAfterCalledCount,
  DateTime? chainGateNow,
}) {
  if (!effectiveAutoBingo ||
      !gameAllowsClaims ||
      winnerWindowExpired ||
      !sessionRoundMatches ||
      cartela == null ||
      cartela.status != GameCartelaStatus.registered ||
      terminalSuppressed) {
    return AutoBingoBlockKind.permanent;
  }

  if (isConfirmingOrClaimingAny ||
      claimStripHoldActive ||
      hasUnresolvedAttemptForCartela ||
      bingoClaimLocked ||
      claimScopeLoading ||
      autoSubmitInFlight ||
      !isChainAutoBingoClaimAllowed(
        game: chainGateGame,
        calledNumbersCount: calledNumbersCount,
        chainBingoArmedAfterCalledCount: chainBingoArmedAfterCalledCount,
        now: chainGateNow,
      )) {
    return AutoBingoBlockKind.temporary;
  }

  return AutoBingoBlockKind.none;
}

/// True when an AUTO submit outcome should terminal-suppress the cartela (R2).
bool shouldTerminalSuppressAutoBingo({
  required BingoClaimStatus? status,
  required bool retryAllowed,
  required String? failureCode,
  required GameCartelaStatus? cartelaStatus,
}) {
  if (isQuietAutoBingoFailureCode(failureCode)) {
    return true;
  }
  if (status == BingoClaimStatus.valid || status == BingoClaimStatus.invalid) {
    return true;
  }
  if ((status == BingoClaimStatus.failed ||
          status == BingoClaimStatus.alreadyResolved) &&
      !retryAllowed) {
    return true;
  }
  if (cartelaStatus == GameCartelaStatus.blocked ||
      cartelaStatus == GameCartelaStatus.winner ||
      cartelaStatus == GameCartelaStatus.cancelled) {
    return true;
  }
  return false;
}

/// After a skipped AUTO submit (beginClaim/persist/eligibility race), release
/// the attempt dedupe key and re-queue instead of burning the completing ball.
bool shouldReleaseAutoBingoAttemptAfterSkip({
  required GameCartelaStatus cartelaStatus,
  required bool alreadyTerminalSuppressed,
}) {
  if (alreadyTerminalSuppressed) {
    return false;
  }
  return cartelaStatus == GameCartelaStatus.registered;
}

/// Re-insert [cartelaId] at the front of [queue] after a recoverable skip.
List<String> requeueAutoBingoCartelaFront({
  required List<String> queue,
  required String cartelaId,
}) {
  final without = queue.where((id) => id != cartelaId);
  return [cartelaId, ...without];
}
