import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../providers/current_big_game_provider.dart';

/// Big-Game-only pre-mount refresh so embedded [LiveGameScreen] starts from
/// fresh session truth without changing Normal/Bonus/BIG_GOTD bootstrap.
class BigGameLiveBootstrap {
  const BigGameLiveBootstrap._();

  /// Refresh `/games/big-game/current`, then load session detail for the
  /// active session. Preserves Big Game–only fields (previousRound, tickets,
  /// held state) from the current card onto the session snapshot.
  static Future<GameModel?> prepareEmbeddedGame(
    WidgetRef ref, {
    required GameModel seed,
  }) async {
    await ref.read(currentBigGameProvider.notifier).refresh();
    final current = ref.read(currentBigGameProvider).value ?? seed;

    // Finished-summary pin seed (Round N) must load THAT session even when
    // /big-game/current operational primary is already Round N+1 READY.
    final pinTerminalSeed = seed.status == GameStatus.finished ||
        seed.status == GameStatus.noWinner;
    final sessionId = pinTerminalSeed
        ? (seed.sessionId ?? current.sessionId)
        : (current.sessionId ?? seed.sessionId);
    if (sessionId == null || sessionId.isEmpty) {
      return pinTerminalSeed ? seed : current;
    }

    try {
      final detail = await ref
          .read(gamesRepositoryProvider)
          .getSessionDetail(sessionId);
      final cardForMerge = pinTerminalSeed ? seed : current;
      final merged =
          _mergeBigGameCardOntoSession(card: cardForMerge, session: detail);
      if (!pinTerminalSeed) {
        return merged;
      }
      // Preserve Round N+1 secondary from the pin seed / operational card.
      final nextRound = seed.nextRoundRegistration ??
          (current.sessionId != null &&
                  current.sessionId != seed.sessionId &&
                  (current.status == GameStatus.ready ||
                      current.status == GameStatus.next)
              ? current
              : null);
      return merged.copyWith(
        status: seed.status,
        finishedAt: seed.finishedAt ?? merged.finishedAt,
        roundIndex: seed.roundIndex ?? merged.roundIndex,
        nextRoundRegistration:
            nextRound ?? merged.nextRoundRegistration,
        nextRoundStartsAt:
            seed.nextRoundStartsAt ?? merged.nextRoundStartsAt,
        canRegister: false,
        registrationOpen: false,
      );
    } catch (_) {
      // Keep card snapshot if session detail fails — LiveGameScreen still mounts.
      return pinTerminalSeed ? seed : current;
    }
  }

  static GameModel _mergeBigGameCardOntoSession({
    required GameModel card,
    required GameModel session,
  }) {
    return session.copyWith(
      previousRound: card.previousRound ?? session.previousRound,
      finishedRounds: card.finishedRounds ?? session.finishedRounds,
      bigGameTicketBalance:
          card.bigGameTicketBalance ?? session.bigGameTicketBalance,
      roundCount: card.roundCount ?? session.roundCount,
      currentRound: card.currentRound ?? session.currentRound,
      roundIndex: session.roundIndex ?? card.roundIndex,
      roundPrizes: card.roundPrizes ?? session.roundPrizes,
      roundPrizeAmount: card.roundPrizeAmount ?? session.roundPrizeAmount,
      nextRoundStartsAt: card.nextRoundStartsAt ?? session.nextRoundStartsAt,
      scheduledStartAt: session.scheduledStartAt ?? card.scheduledStartAt,
      registrationOpensAt:
          session.registrationOpensAt ?? card.registrationOpensAt,
      // Session detail is single-session; keep concurrent next READY from card.
      nextRoundRegistration:
          card.nextRoundRegistration ?? session.nextRoundRegistration,
      // Prefer session canRegister/status (authoritative for live), but keep
      // card held/blocker metadata for Big Game chrome.
    ).copyWithHeld(
      heldWaitingForLiveSlot: card.heldWaitingForLiveSlot,
      blockingLiveGame: card.blockingLiveGame,
    );
  }
}

extension on GameModel {
  GameModel copyWithHeld({
    required bool heldWaitingForLiveSlot,
    BlockingLiveGameSummary? blockingLiveGame,
  }) {
    // GameModel has no copyWith for held fields; rebuild via copyWith where
    // possible and fall back to this helper using the public constructor fields
    // that already exist on the instance.
    return GameModel(
      id: id,
      sessionId: sessionId,
      staticCode: staticCode,
      playCode: playCode,
      name: name,
      gameRule: gameRule,
      gameType: gameType,
      entryFee: entryFee,
      prizePerCartela: prizePerCartela,
      companyFeePerCartela: companyFeePerCartela,
      prizeAmount: prizeAmount,
      companyRevenue: companyRevenue,
      status: status,
      playOrder: playOrder,
      startedAt: startedAt,
      finishedAt: finishedAt,
      cancelledReason: cancelledReason,
      winnerCartelaId: winnerCartelaId,
      winnerWindowEndsAt: winnerWindowEndsAt,
      noWinnerGraceEndsAt: noWinnerGraceEndsAt,
      noWinnerReason: noWinnerReason,
      nextAutoCallAt: nextAutoCallAt,
      autoCallIntervalMs: autoCallIntervalMs,
      createdAt: createdAt,
      updatedAt: updatedAt,
      registeredCartelasCount: registeredCartelasCount,
      calledNumbersCount: calledNumbersCount,
      registrationOpen: registrationOpen,
      canRegister: canRegister,
      scheduledStartAt: scheduledStartAt,
      registrationOpensAt: registrationOpensAt,
      operationMode: operationMode,
      registeredCartelasSummary: registeredCartelasSummary,
      winnerPayoutsSummary: winnerPayoutsSummary,
      sessionOutcomeSummary: sessionOutcomeSummary,
      category: category,
      fixedPrizeAmount: fixedPrizeAmount,
      maxCartelasPerPlayer: maxCartelasPerPlayer,
      heldWaitingForLiveSlot: heldWaitingForLiveSlot,
      blockingLiveGame: blockingLiveGame,
      latestCalledNumberIdentity: latestCalledNumberIdentity,
      roundCount: roundCount,
      currentRound: currentRound,
      roundIndex: roundIndex,
      roundPrizes: roundPrizes,
      roundPrizeAmount: roundPrizeAmount,
      nextRoundStartsAt: nextRoundStartsAt,
      bigGameTicketBalance: bigGameTicketBalance,
      previousRound: previousRound,
      finishedRounds: finishedRounds,
      nextRoundRegistration: nextRoundRegistration,
    );
  }
}
