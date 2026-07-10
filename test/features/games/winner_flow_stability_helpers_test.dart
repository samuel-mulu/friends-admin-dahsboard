import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
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

      expect(isCompleteWinnerResultForModal(sticky, hasApiRow: false), isFalse);
      expect(
        winnerResultsForModal(displayResults: [sticky], apiResults: const []),
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

      expect(isCompleteWinnerResultForModal(api, hasApiRow: true), isTrue);
      expect(winnerResultsForModal(displayResults: [api], apiResults: [api]), [
        api,
      ]);
    });

    test('dialog ready requires post-summary and API-backed modal rows', () {
      const sticky = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 42,
        amount: '0',
        owner: 'ME',
        columns: <List<String>>[
          <String>['1', '2', '3', '4', '5'],
          <String>['16', '17', '18', '19', '20'],
          <String>['31', '32', 'FREE', '34', '35'],
          <String>['46', '47', '48', '49', '50'],
          <String>['61', '62', '63', '64', '65'],
        ],
        completedPatterns: [pattern],
      );
      const api = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 42,
        amount: '25.00',
        columns: <List<String>>[
          <String>['1', '2', '3', '4', '5'],
          <String>['16', '17', '18', '19', '20'],
          <String>['31', '32', 'FREE', '34', '35'],
          <String>['46', '47', '48', '49', '50'],
          <String>['61', '62', '63', '64', '65'],
        ],
        completedPatterns: [pattern],
      );

      final stickyOnlyModal = winnerResultsForModal(
        displayResults: [sticky],
        apiResults: const [],
      );
      final apiModal = winnerResultsForModal(
        displayResults: [api],
        apiResults: [api],
      );

      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: false,
          eligibleViewer: true,
          modalResults: apiModal,
        ),
        isFalse,
      );
      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: true,
          eligibleViewer: false,
          modalResults: apiModal,
        ),
        isFalse,
      );
      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: true,
          eligibleViewer: true,
          modalResults: stickyOnlyModal,
        ),
        isFalse,
      );
      expect(
        winnerDialogReadyForImmediateShow(
          postGameSummaryVisible: true,
          eligibleViewer: true,
          modalResults: apiModal,
        ),
        isTrue,
      );
    });

    test(
      'sticky local winner can recover owned cartela number before API row arrives',
      () {
        final display = sessionWinnerResultsForDisplay(
          apiResults: const [],
          claimPatternsByGameCartelaId: const {
            'gc-1': [pattern],
          },
          myCartelas: [
            GameCartelaModel(
              id: 'gc-1',
              gameId: 'session-1',
              userId: 'user-1',
              cartelaId: 'c-1',
              status: GameCartelaStatus.registered,
              isWinner: false,
              blockedAt: null,
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
              cartela: CartelaModel(
                id: 'c-1',
                number: 88,
                createdAt: DateTime.utc(2026, 1, 1),
                b: const ['1', '2', '3', '4', '5'],
                i: const ['16', '17', '18', '19', '20'],
                n: const ['31', '32', 'FREE', '34', '35'],
                g: const ['46', '47', '48', '49', '50'],
                o: const ['61', '62', '63', '64', '65'],
              ),
            ),
          ],
        );

        expect(display, hasLength(1));
        expect(display.single.cartelaNumber, 88);
        expect(displayableWinnerResults(display), hasLength(1));
      },
    );
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
