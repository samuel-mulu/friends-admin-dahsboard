import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_transition_lock.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/session_winner_results_for_display.dart';

void main() {
  const pattern = CompletedPatternModel(
    type: 'FULL_HOUSE',
    numbers: [1, 2, 3],
    highlightCellIndexes: {0, 1, 2},
  );

  group('shouldPinTerminalSession', () {
    test('pins active winnerWindow', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.winnerWindow,
          postGameSummaryReviewActive: false,
        ),
        isTrue,
      );
    });

    test('pins finished and noWinner', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.finished,
          postGameSummaryReviewActive: false,
        ),
        isTrue,
      );
      expect(
        shouldPinTerminalSession(
          status: GameStatus.noWinner,
          postGameSummaryReviewActive: false,
        ),
        isTrue,
      );
    });

    test('does not pin playing', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.playing,
          postGameSummaryReviewActive: false,
        ),
        isFalse,
      );
    });
  });

  group('winner modal completeness', () {
    test('rejects sticky placeholder without API row', () {
      const sticky = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 0,
        amount: '0',
        columns: <List<String>>[],
        completedPatterns: [pattern],
      );

      expect(
        isCompleteWinnerResultForModal(sticky, hasApiRow: false),
        isFalse,
      );
      expect(
        winnerResultsForModal(
          displayResults: [sticky],
          apiResults: const [],
        ),
        isEmpty,
      );
    });

    test('accepts API-backed row with cartela number and patterns', () {
      const api = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 42,
        amount: '25.00',
        columns: <List<String>>[],
        completedPatterns: [pattern],
      );

      expect(
        isCompleteWinnerResultForModal(api, hasApiRow: true),
        isTrue,
      );
      expect(
        winnerResultsForModal(
          displayResults: [api],
          apiResults: [api],
        ),
        [api],
      );
    });

    test('dialog ready requires post-summary and loaded API results', () {
      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: false,
          hasStickyWinnerPayload: true,
          winnerResultsLoaded: true,
        ),
        isFalse,
      );
      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: true,
          hasStickyWinnerPayload: true,
          winnerResultsLoaded: false,
        ),
        isFalse,
      );
      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: true,
          hasStickyWinnerPayload: false,
          winnerResultsLoaded: true,
        ),
        isTrue,
      );
    });
  });

  group('isReadyTransitionLockOutcomeKnown', () {
    test('returns false when operations is null', () {
      final now = DateTime.utc(2026, 7, 10, 8);
      final snapshot = GameModel.fromOperationJson({
        'id': 'slot-1',
        'sessionId': 'sess-1',
        'staticCode': 'A1',
        'playCode': 'P1',
        'name': 'Test',
        'status': 'READY',
        'entryFee': '10',
        'prizeAmount': '100',
        'registeredCartelasCount': 1,
        'calledNumbersCount': 0,
        'registrationOpen': true,
        'canRegister': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'gameRule': {'id': 'r1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
        'gameType': {'id': 't1', 'key': 'NORMAL', 'name': 'Normal'},
      });
      final lock = ReadyTransitionLock(
        sessionId: 'sess-1',
        reason: ReadyTransitionReason.preparingToPlay,
        startedAt: now,
        snapshotGame: snapshot,
      );

      expect(
        isReadyTransitionLockOutcomeKnown(
          lock: lock,
          operations: null,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
