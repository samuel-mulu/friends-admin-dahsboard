import '../../../../core/utils/api_date_time.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';

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

/// Local winner-window expiry must not invent FINISHED for a Chain Game.
/// Mid-chain the session stays PLAYING; the last round waits for canonical
/// FINISHED from `game:finished`. [hasRemainingChainRounds] is unsafe here
/// because finalize already advances `roundIndex` onto the next round.
bool shouldSkipLocalChainWinnerWindowFinish(GameModel? game) {
  return game != null && game.isChainGame;
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
