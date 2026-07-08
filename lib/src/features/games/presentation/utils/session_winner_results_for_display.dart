import '../../data/models/completed_pattern_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/session_winner_result_model.dart';

bool isDisplayableWinnerAmount(String amount) {
  final trimmed = amount.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final parsed = double.tryParse(trimmed);
  return parsed != null && parsed > 0;
}

String _winnerResultDedupeKey(SessionWinnerResultModel result) {
  final gameCartelaId = result.gameCartelaId.trim();
  if (gameCartelaId.isNotEmpty) {
    return 'gameCartelaId:$gameCartelaId';
  }

  final cartelaId = result.cartelaId.trim();
  if (cartelaId.isNotEmpty) {
    return 'cartelaId:$cartelaId';
  }

  final owner = result.owner?.trim();
  if (owner != null && owner.isNotEmpty) {
    return 'cartelaNumberOwner:${result.cartelaNumber}:$owner';
  }

  return 'cartelaNumber:${result.cartelaNumber}';
}

int _winnerResultDisplayCompletenessScore(SessionWinnerResultModel result) {
  var score = 0;
  if (result.completedPatterns.isNotEmpty) {
    score += 8;
  }
  if (result.columns.any((column) => column.isNotEmpty)) {
    score += 4;
  }
  if (isDisplayableWinnerAmount(result.amount)) {
    score += 2;
  }
  if (result.lastCalledNumber != null) {
    score += 1;
  }
  return score;
}

/// Merges live claim snapshots into API winner results for post-game display.
///
/// When [sessionLastCalledNumber] is set (finished/review), every winner uses
/// that single session last ball. Claim snapshots may only fill in
/// [completedPatterns] while winner results are still loading.
List<SessionWinnerResultModel> sessionWinnerResultsForDisplay({
  required List<SessionWinnerResultModel> apiResults,
  required Map<String, List<CompletedPatternModel>> claimPatternsByGameCartelaId,
  SessionWinnerLastCalledNumber? sessionLastCalledNumber,
  List<GameCartelaModel> myCartelas = const [],
  List<WinnerPayoutSummary>? winnerPayoutsSummary,
}) {
  final payoutByCartelaId = <String, WinnerPayoutSummary>{
    for (final payout in winnerPayoutsSummary ?? const <WinnerPayoutSummary>[])
      payout.cartelaId: payout,
  };
  final payoutByNumber = <int, WinnerPayoutSummary>{
    for (final payout in winnerPayoutsSummary ?? const <WinnerPayoutSummary>[])
      payout.cartelaNumber: payout,
  };
  final myCartelaByNumber = <int, GameCartelaModel>{
    for (final cartela in myCartelas) cartela.cartela.number: cartela,
  };
  final myCartelaByCartelaId = <String, GameCartelaModel>{
    for (final cartela in myCartelas) cartela.cartelaId: cartela,
  };

  List<CompletedPatternModel> claimPatternsFor(SessionWinnerResultModel result) {
    final direct = claimPatternsByGameCartelaId[result.gameCartelaId];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final mine = myCartelaByNumber[result.cartelaNumber];
    if (mine != null) {
      final fromMine = claimPatternsByGameCartelaId[mine.id];
      if (fromMine != null && fromMine.isNotEmpty) {
        return fromMine;
      }
    }

    return const [];
  }

  List<List<String>> columnsFor(SessionWinnerResultModel result) {
    if (result.columns.any((column) => column.isNotEmpty)) {
      return result.columns;
    }

    final mine =
        myCartelaByNumber[result.cartelaNumber] ??
        myCartelaByCartelaId[result.cartelaId];
    if (mine != null) {
      return mine.cartela.columns;
    }

    return result.columns;
  }

  String amountFor(SessionWinnerResultModel result) {
    if (isDisplayableWinnerAmount(result.amount)) {
      return result.amount;
    }

    final payout =
        payoutByCartelaId[result.cartelaId] ??
        payoutByNumber[result.cartelaNumber];
    if (payout != null && isDisplayableWinnerAmount(payout.amount)) {
      return payout.amount;
    }

    return result.amount;
  }

  final deduped = <String, SessionWinnerResultModel>{};

  for (final result in apiResults) {
        final claimPatterns = claimPatternsFor(result);
        var updated = result.copyWith(
          amount: amountFor(result),
          columns: columnsFor(result),
        );

        if (claimPatterns.isNotEmpty && updated.completedPatterns.isEmpty) {
          updated = updated.copyWith(completedPatterns: claimPatterns);
        }

        if (sessionLastCalledNumber != null) {
          updated = updated.copyWith(lastCalledNumber: sessionLastCalledNumber);
        }

        final key = _winnerResultDedupeKey(updated);
        final existing = deduped[key];
        if (existing == null ||
            _winnerResultDisplayCompletenessScore(updated) >
                _winnerResultDisplayCompletenessScore(existing)) {
          deduped[key] = updated;
        }
      }

  return deduped.values.toList(growable: false);
}

/// Patterns must come from the server (claim snapshot or winner-results API).
/// Columns alone are not enough to open the finished winner dialog.
bool winnerResultReadyForDisplay(SessionWinnerResultModel result) {
  return result.completedPatterns.isNotEmpty;
}

bool winnerResultsReadyForDisplay(List<SessionWinnerResultModel> results) {
  if (results.isEmpty) {
    return false;
  }

  return results.every(winnerResultReadyForDisplay);
}

