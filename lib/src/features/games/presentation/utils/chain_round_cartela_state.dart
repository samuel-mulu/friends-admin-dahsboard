import '../../../../core/utils/api_date_time.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/session_winner_result_model.dart';
import 'live_round_break.dart';

/// True when session metadata proves a prior Chain round has closed and the
/// current PLAYING view is a later round — not merely a stale same-round
/// PLAYING snapshot.
///
/// Evidence (either is enough):
/// - [GameModel.roundPausedUntil] set by `chain:round_finished` / server pause
/// - [GameModel.roundResults] containing a decided round behind
///   [GameModel.displayRoundIndex]
///
/// [GameModel.displayRoundIndex] alone is never sufficient.
bool hasAuthoritativeChainRoundAdvance(GameModel game) {
  if (!game.isChainGame) {
    return false;
  }
  if (game.roundPausedUntil != null) {
    return true;
  }
  final current = game.displayRoundIndex;
  for (final round in game.roundResults) {
    if (round.roundIndex < current) {
      return true;
    }
  }
  return false;
}

/// After a non-final Chain Game round, winners are REGISTERED again on the
/// server so they can Bingo later. Local `isWinner` patches from round N must
/// not survive into round N+1 once advance is proven. Blocked cartelas stay
/// blocked for the whole chain. Same-round stale PLAYING does not demote
/// WINNER.
List<GameCartelaModel> normalizeChainPlayableCartelas({
  required GameModel? game,
  required List<GameCartelaModel> cartelas,
}) {
  if (game == null ||
      !game.isChainGame ||
      game.status != GameStatus.playing ||
      cartelas.isEmpty ||
      !hasAuthoritativeChainRoundAdvance(game)) {
    return cartelas;
  }

  var changed = false;
  final next = <GameCartelaModel>[];
  for (final cartela in cartelas) {
    if (cartela.status == GameCartelaStatus.blocked ||
        cartela.status == GameCartelaStatus.cancelled) {
      next.add(cartela);
      continue;
    }

    if (cartela.status == GameCartelaStatus.winner || cartela.isWinner) {
      changed = true;
      next.add(
        cartela.copyWith(
          status: GameCartelaStatus.registered,
          isWinner: false,
        ),
      );
      continue;
    }

    next.add(cartela);
  }

  return changed ? List<GameCartelaModel>.unmodifiable(next) : cartelas;
}

/// Local winner-window expiry must not invent FINISHED mid-chain.
///
/// Non-final rounds stay PLAYING with a pause — skip local finish and wait for
/// that path. The last round (`roundIndex == roundCount`, no pause) uses the
/// same local FINISHED → 60s Continue summary as Normal.
bool shouldSkipLocalChainWinnerWindowFinish(GameModel? game) {
  if (game == null || !game.isChainGame) {
    return false;
  }
  // Pause already armed (or still showing) means a non-final round closed.
  if (game.roundPausedUntil != null) {
    return true;
  }
  return game.hasRemainingChainRounds;
}

/// Whether Chain may open the shared final Winner Cartela Dialog (no pause
/// countdown) during the finished PIN summary.
///
/// Requires terminal session state + finished-summary visibility. Does not use
/// `roundIndex == roundCount` alone: refuses active pause, remaining rounds,
/// and (when roundResults exist) a missing last-round result row.
bool shouldShowChainFinalWinnerCartelaDialog({
  required GameModel? game,
  required bool postGameSummaryVisible,
}) {
  if (game == null || !game.isChainGame) {
    return false;
  }
  if (!postGameSummaryVisible) {
    return false;
  }
  if (game.status != GameStatus.finished &&
      game.status != GameStatus.noWinner) {
    return false;
  }
  // Inter-round always keeps PLAYING + pause; refuse any lingering pause.
  if (game.roundPausedUntil != null) {
    return false;
  }
  if (game.hasRemainingChainRounds) {
    return false;
  }
  final lastRound = game.displayRoundCount;
  if (game.roundResults.isNotEmpty &&
      !game.roundResults.any((round) => round.roundIndex == lastRound)) {
    return false;
  }
  return true;
}

/// Chain Game round 2+: from the moment the previous round is decided, Bingo
/// stays off until at least one NEW ball is called for the current round.
/// Carried marks + old balls must never arm the new round's pattern.
///
/// Source of truth, in order:
/// 1. Session data — the previous round's winning ball from
///    [GameModel.roundResults] and the local called strip
///    ([chainRoundHasNewBallSincePreviousWin]). Survives refetch, resume and
///    app restart.
/// 2. Fallback — [armedAfterCalledCount], the strip length recorded when the
///    round transition was observed live (socket path, before a refetch
///    delivers the winning ball).
bool isChainBingoArmedAfterNewBall({
  required GameModel? game,
  required int calledNumbersCount,
  required int? armedAfterCalledCount,
  List<CalledNumberModel> calledNumbers = const [],
}) {
  if (game == null || !game.isChainGame) {
    return true;
  }
  final derived = chainRoundHasNewBallSincePreviousWin(
    game: game,
    calledNumbers: calledNumbers,
  );
  if (derived != null) {
    return derived;
  }
  if (armedAfterCalledCount == null) {
    return true;
  }
  return calledNumbersCount > armedAfterCalledCount;
}

/// Whether a ball was called after the previous Chain round's winning ball.
///
/// Returns null when session data cannot decide (round 1, previous result or
/// its winning ball not known yet, or the winning ball not in [calledNumbers]).
bool? chainRoundHasNewBallSincePreviousWin({
  required GameModel game,
  required List<CalledNumberModel> calledNumbers,
}) {
  if (!game.isChainGame || calledNumbers.isEmpty) {
    return null;
  }
  final currentRound = game.displayRoundIndex;
  if (currentRound <= 1) {
    return null;
  }

  int? winningBall;
  for (final round in game.roundResults) {
    if (round.roundIndex == currentRound - 1) {
      winningBall = round.winningBallNumber;
      break;
    }
  }
  if (winningBall == null) {
    return null;
  }

  int? winningOrder;
  var maxOrder = 0;
  for (final ball in calledNumbers) {
    if (ball.number == winningBall) {
      winningOrder = ball.order;
    }
    if (ball.order > maxOrder) {
      maxOrder = ball.order;
    }
  }
  if (winningOrder == null) {
    return null;
  }
  return maxOrder > winningOrder;
}

/// Winners of a decided Chain round, from session `roundResults`.
///
/// After a non-final round, GameCartela rows are REGISTERED again, so the
/// 20s summary must read winners from this list instead of waiting on the
/// winner-results API.
List<int> winnerCartelaNumbersFromChainRoundResults({
  required List<ChainRoundResultSummary> roundResults,
  required int roundIndex,
}) {
  for (final round in roundResults) {
    if (round.roundIndex != roundIndex) {
      continue;
    }
    return [
      for (final winner in round.winners)
        if (winner.cartelaNumber > 0) winner.cartelaNumber,
    ];
  }
  return const [];
}

/// Pinned "Round winners" bar — only during inter-round pause or terminal
/// finished review. During active PLAYING, use the chain info strip tap instead.
bool shouldShowPinnedChainRoundWinnersBar({
  required GameModel? game,
  required LiveRoundBreakOwner roundBreakOwner,
  required bool postGameSummaryReviewActive,
}) {
  if (game == null || !game.isChainGame) {
    return false;
  }
  final hasDecidedWinners = game.roundResults.any(
    (round) => !round.isForfeited && round.winners.isNotEmpty,
  );
  if (!hasDecidedWinners) {
    return false;
  }

  if (roundBreakOwner == LiveRoundBreakOwner.chainInterRound) {
    return true;
  }
  if (roundBreakOwner == LiveRoundBreakOwner.postGameTerminal &&
      postGameSummaryReviewActive) {
    return true;
  }
  return false;
}

/// Pinned winners bar: show every round when there are few; otherwise round 1,
/// the most recently decided round, and the final round when it has a winner.
List<ChainRoundResultSummary> condensedChainRoundResultsForBar({
  required List<ChainRoundResultSummary> roundResults,
  required int roundCount,
}) {
  final decided = roundResults
      .where((round) => !round.isForfeited && round.winners.isNotEmpty)
      .toList()
    ..sort((a, b) => a.roundIndex.compareTo(b.roundIndex));

  if (decided.length <= 3) {
    return List<ChainRoundResultSummary>.unmodifiable(decided);
  }

  final picked = <int, ChainRoundResultSummary>{};
  void add(ChainRoundResultSummary round) => picked[round.roundIndex] = round;

  add(decided.first);
  add(decided.last);
  for (final round in decided) {
    if (round.roundIndex == roundCount) {
      add(round);
      break;
    }
  }

  final condensed = picked.values.toList()
    ..sort((a, b) => a.roundIndex.compareTo(b.roundIndex));
  return List<ChainRoundResultSummary>.unmodifiable(condensed);
}

/// API modal rows for one finished chain round (not the whole session).
List<SessionWinnerResultModel> chainInterRoundDialogResults({
  required List<SessionWinnerResultModel> modalResults,
  required List<ChainRoundResultSummary> roundResults,
  required int finishedRoundIndex,
}) {
  if (modalResults.isEmpty) {
    return const [];
  }

  ChainRoundResultSummary? finishedRound;
  for (final round in roundResults) {
    if (round.roundIndex == finishedRoundIndex) {
      finishedRound = round;
      break;
    }
  }
  if (finishedRound == null || finishedRound.winners.isEmpty) {
    return const [];
  }

  final cartelaNumbers = {
    for (final winner in finishedRound.winners)
      if (winner.cartelaNumber > 0) winner.cartelaNumber,
  };
  final gameCartelaIds = {
    for (final winner in finishedRound.winners)
      if (winner.gameCartelaId.isNotEmpty) winner.gameCartelaId,
  };

  return modalResults
      .where(
        (result) =>
            gameCartelaIds.contains(result.gameCartelaId) ||
            cartelaNumbers.contains(result.cartelaNumber),
      )
      .toList(growable: false);
}

int? _positiveInt(Object? raw) {
  final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}

/// `chain:round_finished` already lists the round winners. Use them on the
/// 20s banner immediately instead of waiting for winner-results.
List<int> winnerCartelaNumbersFromChainRoundFinishedPayload(
  Map<String, dynamic> payload,
) {
  final winners = payload['winners'];
  if (winners is! List) {
    return const [];
  }

  final numbers = <int>{};
  for (final winner in winners) {
    if (winner is! Map) {
      continue;
    }
    final number = _positiveInt(winner['cartelaNumber']);
    if (number != null) {
      numbers.add(number);
    }
  }
  return numbers.toList(growable: false)..sort();
}

List<ChainRoundWinnerSummary> chainRoundWinnersFromFinishedPayload(
  Map<String, dynamic> payload,
) {
  final winners = payload['winners'];
  if (winners is! List) {
    return const [];
  }

  final parsed = <ChainRoundWinnerSummary>[];
  for (final winner in winners) {
    if (winner is! Map) {
      continue;
    }
    final map = Map<String, dynamic>.from(winner);
    final number = _positiveInt(map['cartelaNumber']);
    if (number == null) {
      continue;
    }
    parsed.add(
      ChainRoundWinnerSummary(
        gameCartelaId: map['gameCartelaId']?.toString() ?? '',
        cartelaNumber: number,
        amount: map['amount']?.toString() ?? '0',
      ),
    );
  }
  return parsed;
}

/// Optimistic PLAYING + pause patch from `chain:round_finished` so the UI
/// leaves winner-window immediately instead of waiting on a refetch.
GameModel applyChainRoundFinishedToGame({
  required GameModel game,
  required Map<String, dynamic> payload,
}) {
  if (!game.isChainGame) {
    return game;
  }

  final pausedUntil = parseApiDateTime(payload['pausedUntil']);
  final nextRoundIndex = _positiveInt(payload['nextRoundIndex']);
  final nextRoundPrize = payload['nextRoundPrizeAmount']?.toString();

  return game.copyWith(
    status: GameStatus.playing,
    roundPausedUntil: pausedUntil ?? game.roundPausedUntil,
    roundIndex: nextRoundIndex ?? game.roundIndex,
    currentRound: nextRoundIndex ?? game.currentRound,
    roundPrizeAmount: (nextRoundPrize != null && nextRoundPrize.isNotEmpty)
        ? nextRoundPrize
        : game.roundPrizeAmount,
    nextAutoCallAt: null,
  );
}
