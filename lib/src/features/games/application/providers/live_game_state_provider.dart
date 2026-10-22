import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../domain/live_game_state.dart';

class LiveGameStateNotifier extends Notifier<LiveGameState> {
  @override
  LiveGameState build() => const LiveGameState.initial();

  void setLoading() {
    state = const LiveGameState.loading();
  }

  void setReady({
    GameModel? game,
    required int remainingSeconds,
    required int registeredCount,
  }) {
    state = LiveGameState.ready(
      game: game,
      remainingSeconds: remainingSeconds,
      registeredCount: registeredCount,
    );
  }

  void setPlaying({
    required GameModel game,
    required List<CalledNumberModel> calledNumbers,
    required List<GameCartelaModel> myCartelas,
    required Map<String, Set<int>> markedCellsByCartelaId,
    bool isClaiming = false,
  }) {
    state = LiveGameState.playing(
      game: game,
      calledNumbers: calledNumbers,
      myCartelas: myCartelas,
      markedCellsByCartelaId: markedCellsByCartelaId,
      isClaiming: isClaiming,
    );
  }

  void updateCalledNumbers(List<CalledNumberModel> numbers) {
    final current = state;
    if (current is LiveGamePlayingState) {
      state = LiveGameState.playing(
        game: current.game,
        calledNumbers: numbers,
        myCartelas: current.myCartelas,
        markedCellsByCartelaId: current.markedCellsByCartelaId,
        isClaiming: current.isClaiming,
      );
    }
  }

  void updateClaiming(bool isClaiming) {
    final current = state;
    if (current is LiveGamePlayingState) {
      state = LiveGameState.playing(
        game: current.game,
        calledNumbers: current.calledNumbers,
        myCartelas: current.myCartelas,
        markedCellsByCartelaId: current.markedCellsByCartelaId,
        isClaiming: isClaiming,
      );
    }
  }

  void setWinnerWindow({
    required GameModel game,
    required int windowSecondsRemaining,
    required List<String> winnerNames,
  }) {
    state = LiveGameState.winnerWindow(
      game: game,
      windowSecondsRemaining: windowSecondsRemaining,
      winnerNames: winnerNames,
    );
  }

  void setFinished({
    required GameModel game,
    required SessionWinnerResultModel results,
  }) {
    state = LiveGameState.finished(
      game: game,
      results: results,
    );
  }

  void setCancelled({required String reason}) {
    state = LiveGameState.cancelled(reason: reason);
  }

  void setError(String message) {
    state = LiveGameState.error(message);
  }

  void reset() {
    state = const LiveGameState.initial();
  }
}

final liveGameStateNotifierProvider =
    NotifierProvider<LiveGameStateNotifier, LiveGameState>(
  LiveGameStateNotifier.new,
);
