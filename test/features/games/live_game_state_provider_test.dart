import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_game_state.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/live_game_state_provider.dart';

void main() {
  group('LiveGameStateNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    final mockGame = GameModel.fromLiveJson({
      'id': 'game-1',
      'sessionId': 'session-1',
      'status': 'PLAYING',
      'entryFee': '10',
      'prizeAmount': '100',
      'registeredCartelasCount': 5,
    });

    test('initial state is LiveGameState.initial', () {
      final state = container.read(liveGameStateNotifierProvider);
      expect(state, const LiveGameState.initial());
      expect(state.isLoading, isFalse);
      expect(state.isPlaying, isFalse);
    });

    test('transitions through full game lifecycle', () {
      final notifier = container.read(liveGameStateNotifierProvider.notifier);

      // 1. Loading
      notifier.setLoading();
      expect(container.read(liveGameStateNotifierProvider).isLoading, isTrue);

      // 2. Ready
      notifier.setReady(
        game: mockGame,
        remainingSeconds: 15,
        registeredCount: 8,
      );
      final readyState = container.read(liveGameStateNotifierProvider);
      expect(readyState.isReady, isTrue);
      expect((readyState as LiveGameReadyState).remainingSeconds, 15);
      expect(readyState.registeredCount, 8);

      // 3. Playing
      final ball1 = CalledNumberModel(
        id: 'c-1',
        sessionId: 'session-1',
        number: 42,
        letter: 'N',
        order: 1,
        createdAt: DateTime.now(),
      );
      notifier.setPlaying(
        game: mockGame,
        calledNumbers: [ball1],
        myCartelas: const [],
        markedCellsByCartelaId: {'cartela-1': {42}},
      );
      final playingState = container.read(liveGameStateNotifierProvider);
      expect(playingState.isPlaying, isTrue);
      final p = playingState as LiveGamePlayingState;
      expect(p.calledNumbers.length, 1);
      expect(p.isClaiming, isFalse);

      // 4. Update called numbers
      final ball2 = CalledNumberModel(
        id: 'c-2',
        sessionId: 'session-1',
        number: 12,
        letter: 'B',
        order: 2,
        createdAt: DateTime.now(),
      );
      notifier.updateCalledNumbers([ball1, ball2]);
      final p2 = container.read(liveGameStateNotifierProvider) as LiveGamePlayingState;
      expect(p2.calledNumbers.length, 2);

      // 5. Update claiming
      notifier.updateClaiming(true);
      final p3 = container.read(liveGameStateNotifierProvider) as LiveGamePlayingState;
      expect(p3.isClaiming, isTrue);

      // 6. Winner window
      notifier.setWinnerWindow(
        game: mockGame,
        windowSecondsRemaining: 10,
        winnerNames: ['Abebe', 'Kebede'],
      );
      final winState = container.read(liveGameStateNotifierProvider);
      expect(winState.isWinnerWindow, isTrue);
      final w = winState as LiveGameWinnerWindowState;
      expect(w.winnerNames, ['Abebe', 'Kebede']);

      // 7. Finished
      final mockResults = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'cartela-1',
        cartelaNumber: 42,
        amount: '50',
        columns: const [],
        completedPatterns: const [],
      );
      notifier.setFinished(game: mockGame, results: mockResults);
      final finState = container.read(liveGameStateNotifierProvider);
      expect(finState.isFinished, isTrue);
      final f = finState as LiveGameFinishedState;
      expect(f.results.cartelaNumber, 42);

      // 8. Reset
      notifier.reset();
      expect(container.read(liveGameStateNotifierProvider), const LiveGameState.initial());
    });

    test('error and cancelled states transition correctly', () {
      final notifier = container.read(liveGameStateNotifierProvider.notifier);

      notifier.setError('Network disconnected');
      expect(container.read(liveGameStateNotifierProvider), isA<LiveGameState>());

      notifier.setCancelled(reason: 'Admin aborted');
      final cancelled = container.read(liveGameStateNotifierProvider);
      expect(cancelled.isCancelled, isTrue);
      expect((cancelled as LiveGameCancelledState).reason, 'Admin aborted');
    });
  });
}
