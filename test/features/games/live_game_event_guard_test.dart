import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_event_guard.dart';

final _now = DateTime.utc(2026, 8, 5, 12);

GameModel _stubGame({required String sessionId}) {
  return GameModel(
    id: 'id-$sessionId',
    sessionId: sessionId,
    staticCode: 'CODE-$sessionId',
    playCode: 'P-$sessionId',
    name: 'Game $sessionId',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '80',
    companyRevenue: '0',
    status: GameStatus.playing,
    playOrder: 1,
    startedAt: _now,
    finishedAt: null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: false,
    canRegister: false,
  );
}

void main() {
  group('shouldWakeEmptyLiveBoard', () {
    test('true when no primary game and no tracked registration', () {
      expect(
        shouldWakeEmptyLiveBoard(
          game: null,
          trackedRegistrationSessionId: null,
        ),
        isTrue,
      );
    });

    test('false when primary game is present', () {
      expect(
        shouldWakeEmptyLiveBoard(
          game: _stubGame(sessionId: 'session-a'),
          trackedRegistrationSessionId: null,
        ),
        isFalse,
      );
    });

    test('false when registration session is tracked on empty primary', () {
      expect(
        shouldWakeEmptyLiveBoard(
          game: null,
          trackedRegistrationSessionId: 'session-reg',
        ),
        isFalse,
      );
    });
  });

  group('eventAffectsCurrentGame empty board', () {
    test('still returns false when game is null (finish path unchanged)', () {
      expect(
        eventAffectsCurrentGame(
          game: null,
          activeSessionId: null,
          eventSessionId: 'session-new',
          eventSlotId: 'slot-new',
        ),
        isFalse,
      );
    });
  });
}
