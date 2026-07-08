import '../../data/models/completed_pattern_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../domain/winning_ball_cell.dart';
import 'cartela_pattern_progress_overlay.dart';

/// Live-session cache for winner pattern overlays and per-cartela winning ball.
class WinnerCartelaDisplayCache {
  final Map<String, Set<int>> patternCellsByGameCartelaId = {};
  final Map<String, CartelaPatternProgressOverlay> overlayByGameCartelaId = {};
  final Map<String, List<CompletedPatternModel>> claimPatternsByGameCartelaId =
      {};
  final Map<String, int> winningBallCellIndexByGameCartelaId = {};

  void clear() {
    patternCellsByGameCartelaId.clear();
    overlayByGameCartelaId.clear();
    claimPatternsByGameCartelaId.clear();
    winningBallCellIndexByGameCartelaId.clear();
  }

  void storePatterns({
    required String gameCartelaId,
    required List<CompletedPatternModel> patterns,
    List<List<String>>? columns,
    SessionWinnerLastCalledNumber? lastCalledNumber,
  }) {
    if (patterns.isEmpty) {
      return;
    }

    patternCellsByGameCartelaId[gameCartelaId] =
        CompletedPatternModel.mergedHighlightIndexes(patterns);
    overlayByGameCartelaId[gameCartelaId] =
        CartelaPatternProgressOverlay.fromCompletedPatterns(patterns);

    final winningBall = resolveLiveWinningBallCellIndex(
      columns: columns,
      patterns: patterns,
      lastCalledNumber: lastCalledNumber,
    );
    if (winningBall != null) {
      winningBallCellIndexByGameCartelaId[gameCartelaId] = winningBall;
    } else {
      winningBallCellIndexByGameCartelaId.remove(gameCartelaId);
    }
  }

  void storeClaimSnapshot({
    required String gameCartelaId,
    required List<CompletedPatternModel> patterns,
    List<List<String>>? columns,
    SessionWinnerLastCalledNumber? lastCalledNumber,
  }) {
    if (patterns.isEmpty) {
      return;
    }

    claimPatternsByGameCartelaId[gameCartelaId] = patterns;
    storePatterns(
      gameCartelaId: gameCartelaId,
      patterns: patterns,
      columns: columns,
      lastCalledNumber: lastCalledNumber,
    );
  }

  void applySessionResult(SessionWinnerResultModel result) {
    if (result.completedPatterns.isNotEmpty) {
      storePatterns(
        gameCartelaId: result.gameCartelaId,
        patterns: result.completedPatterns,
        columns: result.columns,
        lastCalledNumber: result.lastCalledNumber,
      );
      final resolved = result.resolvedWinningBallCellIndex;
      if (resolved != null) {
        winningBallCellIndexByGameCartelaId[result.gameCartelaId] = resolved;
      } else {
        winningBallCellIndexByGameCartelaId.remove(result.gameCartelaId);
      }
      return;
    }

    final claimPatterns = claimPatternsByGameCartelaId[result.gameCartelaId];
    if (claimPatterns != null && claimPatterns.isNotEmpty) {
      storePatterns(
        gameCartelaId: result.gameCartelaId,
        patterns: claimPatterns,
        columns: result.columns,
        lastCalledNumber: result.lastCalledNumber,
      );
    }
  }
}

int? resolveLiveWinningBallCellIndex({
  required List<List<String>>? columns,
  required List<CompletedPatternModel> patterns,
  SessionWinnerLastCalledNumber? lastCalledNumber,
}) {
  if (columns == null || lastCalledNumber == null || patterns.isEmpty) {
    return null;
  }

  return resolveWinningBallCellIndex(
    columns: columns,
    highlightCellIndexes: CompletedPatternModel.mergedHighlightIndexes(patterns),
    lastCalledNumber: lastCalledNumber,
  );
}
