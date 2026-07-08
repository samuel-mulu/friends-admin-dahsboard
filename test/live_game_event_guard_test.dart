import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_event_guard.dart';

GameModel _game({
  required String slotId,
  String? sessionId,
  GameStatus status = GameStatus.playing,
}) {
  return GameModel.fromOperationJson({
    'slotId': slotId,
    'sessionId': sessionId,
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-1',
    'playerStatus': status == GameStatus.playing ? 'playing' : 'registrationOpen',
    'rawStatus': status.name.toUpperCase(),
    'operationMode': 'AUTO',
    'canRegister': false,
    'registrationOpen': false,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '0',
    'registeredCartelasCount': 0,
    'calledNumbersCount': 0,
    'gameRule': {
      'id': 'rule-1',
      'key': 'FULL_HOUSE',
      'name': 'Full House',
    },
  });
}

void main() {
  group('eventAffectsCurrentGame', () {
    test('ignores old session on same slot', () {
      final game = _game(
        slotId: 'slot-1',
        sessionId: 'session-new',
        status: GameStatus.playing,
      );

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: 'session-new',
          eventSessionId: 'session-old',
          eventSlotId: 'slot-1',
        ),
        isFalse,
      );
    });

    test('accepts matching active session', () {
      final game = _game(slotId: 'slot-1', sessionId: 'session-1');

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: 'session-1',
          eventSessionId: 'session-1',
          eventSlotId: 'slot-1',
        ),
        isTrue,
      );
    });

    test('ignores events when no current game is selected', () {
      expect(
        eventAffectsCurrentGame(
          game: null,
          activeSessionId: null,
          eventSessionId: 'session-1',
          eventSlotId: 'slot-1',
        ),
        isFalse,
      );
    });

    test('allows slot fallback for pre-session game', () {
      final game = _game(
        slotId: 'slot-1',
        sessionId: null,
        status: GameStatus.next,
      );

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: null,
          eventSessionId: null,
          eventSlotId: 'slot-1',
        ),
        isTrue,
      );
    });

    test('rejects slot-only events once a live session is active', () {
      final game = _game(slotId: 'slot-1', sessionId: null);

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: null,
          eventSessionId: null,
          eventSlotId: 'slot-1',
        ),
        isTrue,
      );

      expect(
        eventAffectsCurrentGame(
          game: _game(slotId: 'slot-1', sessionId: 'session-1'),
          activeSessionId: 'session-1',
          eventSessionId: null,
          eventSlotId: 'slot-1',
        ),
        isFalse,
      );
    });

    test('rejects finished-session event after slot reuse', () {
      final game = _game(
        slotId: 'slot-1',
        sessionId: 'session-new',
        status: GameStatus.playing,
      );

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: 'session-new',
          eventSessionId: 'session-old-finished',
          eventSlotId: 'slot-1',
        ),
        isFalse,
      );
    });

    test('accepts next registration session while live session is active', () {
      final game = _game(
        slotId: 'slot-1',
        sessionId: 'session-live',
        status: GameStatus.playing,
      );

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: 'session-live',
          eventSessionId: 'session-next-reg',
          eventSlotId: null,
          trackedRegistrationSessionId: 'session-next-reg',
        ),
        isTrue,
      );
    });

    test('rejects unrelated session when tracked registration is set', () {
      final game = _game(
        slotId: 'slot-1',
        sessionId: 'session-live',
        status: GameStatus.playing,
      );

      expect(
        eventAffectsCurrentGame(
          game: game,
          activeSessionId: 'session-live',
          eventSessionId: 'session-other',
          eventSlotId: null,
          trackedRegistrationSessionId: 'session-next-reg',
        ),
        isFalse,
      );
    });
  });

  group('eventAffectsTrackedRegistrationSession', () {
    test('accepts exact tracked registration session', () {
      expect(
        eventAffectsTrackedRegistrationSession(
          trackedRegistrationSessionId: 'session-ready',
          eventSessionId: 'session-ready',
        ),
        isTrue,
      );
    });

    test('ignores old or unrelated registration sessions', () {
      expect(
        eventAffectsTrackedRegistrationSession(
          trackedRegistrationSessionId: 'session-ready',
          eventSessionId: 'session-old',
        ),
        isFalse,
      );
      expect(
        eventAffectsTrackedRegistrationSession(
          trackedRegistrationSessionId: 'session-ready',
          eventSessionId: null,
        ),
        isFalse,
      );
    });
  });

  group('isLivePlayGameStatus', () {
    test('registration statuses are not live play', () {
      expect(isLivePlayGameStatus(GameStatus.ready), isFalse);
      expect(isLivePlayGameStatus(GameStatus.next), isFalse);
    });

    test('playing and terminal live statuses count as live play', () {
      expect(isLivePlayGameStatus(GameStatus.playing), isTrue);
      expect(isLivePlayGameStatus(GameStatus.finished), isTrue);
    });
  });
}
