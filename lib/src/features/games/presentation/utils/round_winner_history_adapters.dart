import '../../data/models/game_model.dart';
import '../../data/models/round_winner_history_model.dart';
import '../../data/models/session_winner_result_model.dart';
import 'big_game_live_presentation.dart';
import 'chain_round_cartela_state.dart';

/// Whether the final finished PIN summary may show All Rounds Winners.
///
/// Uses authoritative terminal / final-round metadata — not countdown zero or
/// an approximate client round counter.
bool shouldShowAllRoundsWinnersHistory({
  required GameModel? game,
  required bool postGameSummaryVisible,
}) {
  if (game == null || !postGameSummaryVisible) {
    return false;
  }

  if (game.isBigGame) {
    return isBigGameFinalTerminalCard(game);
  }

  if (game.isChainGame) {
    return shouldShowChainFinalWinnerCartelaDialog(
      game: game,
      postGameSummaryVisible: postGameSummaryVisible,
    );
  }

  return false;
}

/// Stable cache key so history is not re-fetched on every rebuild.
String? allRoundsWinnerHistoryCacheKey(GameModel? game) {
  if (game == null) {
    return null;
  }
  if (game.isBigGame) {
    return 'big:${game.id}';
  }
  if (game.isChainGame) {
    final sessionId = game.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    return 'chain:$sessionId';
  }
  return null;
}

/// Flatten history into per-winner cards for the shared widget.
List<AllRoundsWinnerCardData> adaptRoundWinnerHistoryToCards(
  RoundWinnerHistory history,
) {
  final cards = <AllRoundsWinnerCardData>[];
  for (final round in history.rounds) {
    if (round.isNoWinner || !round.hasWinners) {
      cards.add(
        AllRoundsWinnerCardData(
          roundIndex: round.roundIndex,
          roundCount: history.roundCount,
          cartelaNumber: null,
          amount: null,
          prizeAmount: round.prizeAmount,
          isNoWinner: true,
          winnerResults: const [],
        ),
      );
      continue;
    }

    for (final winner in round.winnerResults) {
      cards.add(
        AllRoundsWinnerCardData(
          roundIndex: round.roundIndex,
          roundCount: history.roundCount,
          cartelaNumber: winner.cartelaNumber,
          amount: winner.amount,
          prizeAmount: round.prizeAmount,
          isNoWinner: false,
          phoneNumber: winner.phoneNumber,
          owner: winner.owner,
          winnerResults: round.winnerResults,
          selectedGameCartelaId: winner.gameCartelaId,
        ),
      );
    }
  }
  return List<AllRoundsWinnerCardData>.unmodifiable(cards);
}

class AllRoundsWinnerCardData {
  const AllRoundsWinnerCardData({
    required this.roundIndex,
    required this.roundCount,
    required this.cartelaNumber,
    required this.amount,
    required this.prizeAmount,
    required this.isNoWinner,
    required this.winnerResults,
    this.phoneNumber,
    this.owner,
    this.selectedGameCartelaId,
  });

  final int roundIndex;
  final int roundCount;
  final int? cartelaNumber;
  final String? amount;
  final String prizeAmount;
  final bool isNoWinner;
  final String? phoneNumber;
  final String? owner;
  final List<SessionWinnerResultModel> winnerResults;
  final String? selectedGameCartelaId;

  bool get isMine => owner == 'ME';
}
