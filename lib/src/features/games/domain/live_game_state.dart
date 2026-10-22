import '../data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../data/models/game_model.dart';
import '../data/models/session_winner_result_model.dart';

sealed class LiveGameState {
  const LiveGameState();

  const factory LiveGameState.initial() = _Initial;
  const factory LiveGameState.loading() = _Loading;
  const factory LiveGameState.ready({
    GameModel? game,
    required int remainingSeconds,
    required int registeredCount,
  }) = LiveGameReadyState;
  const factory LiveGameState.playing({
    required GameModel game,
    required List<CalledNumberModel> calledNumbers,
    required List<GameCartelaModel> myCartelas,
    required Map<String, Set<int>> markedCellsByCartelaId,
    required bool isClaiming,
  }) = LiveGamePlayingState;
  const factory LiveGameState.winnerWindow({
    required GameModel game,
    required int windowSecondsRemaining,
    required List<String> winnerNames,
  }) = LiveGameWinnerWindowState;
  const factory LiveGameState.finished({
    required GameModel game,
    required SessionWinnerResultModel results,
  }) = LiveGameFinishedState;
  const factory LiveGameState.cancelled({
    required String reason,
  }) = LiveGameCancelledState;
  const factory LiveGameState.error(String message) = _Error;

  bool get isLoading => this is _Loading;
  bool get isReady => this is LiveGameReadyState;
  bool get isPlaying => this is LiveGamePlayingState;
  bool get isWinnerWindow => this is LiveGameWinnerWindowState;
  bool get isFinished => this is LiveGameFinishedState;
  bool get isCancelled => this is LiveGameCancelledState;
}

class _Initial extends LiveGameState {
  const _Initial();
}

class _Loading extends LiveGameState {
  const _Loading();
}

class LiveGameReadyState extends LiveGameState {
  const LiveGameReadyState({
    this.game,
    required this.remainingSeconds,
    required this.registeredCount,
  });
  final GameModel? game;
  final int remainingSeconds;
  final int registeredCount;
}

class LiveGamePlayingState extends LiveGameState {
  const LiveGamePlayingState({
    required this.game,
    required this.calledNumbers,
    required this.myCartelas,
    required this.markedCellsByCartelaId,
    required this.isClaiming,
  });
  final GameModel game;
  final List<CalledNumberModel> calledNumbers;
  final List<GameCartelaModel> myCartelas;
  final Map<String, Set<int>> markedCellsByCartelaId;
  final bool isClaiming;
}

class LiveGameWinnerWindowState extends LiveGameState {
  const LiveGameWinnerWindowState({
    required this.game,
    required this.windowSecondsRemaining,
    required this.winnerNames,
  });
  final GameModel game;
  final int windowSecondsRemaining;
  final List<String> winnerNames;
}

class LiveGameFinishedState extends LiveGameState {
  const LiveGameFinishedState({
    required this.game,
    required this.results,
  });
  final GameModel game;
  final SessionWinnerResultModel results;
}

class LiveGameCancelledState extends LiveGameState {
  const LiveGameCancelledState({
    required this.reason,
  });
  final String reason;
}

class _Error extends LiveGameState {
  const _Error(this.message);
  final String message;
}
