import '../../../../core/utils/api_date_time.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/session_winner_result_model.dart';

/// After a non-final Chain Game round, winners are REGISTERED again on the
/// server so they can Bingo later. Local `isWinner` patches from round 1 must
/// not survive into round 2. Blocked cartelas stay blocked for the whole chain.
List<GameCartelaModel> normalizeChainPlayableCartelas({
  required GameModel? game,
  required List<GameCartelaModel> cartelas,
}) {
  if (game == null ||
      !game.isChainGame ||
      game.status != GameStatus.playing ||
      cartelas.isEmpty) {
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

/// After a new Chain round becomes playable, Bingo stays off until at least
/// one new auto-call ball arrives. Carried marks + old balls must not arm it.
bool isChainBingoArmedAfterNewBall({
  required GameModel? game,
  required int calledNumbersCount,
  required int? armedAfterCalledCount,
}) {
  if (game == null || !game.isChainGame) {
    return true;
  }
  if (armedAfterCalledCount == null) {
    return true;
  }
  return calledNumbersCount > armedAfterCalledCount;
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
