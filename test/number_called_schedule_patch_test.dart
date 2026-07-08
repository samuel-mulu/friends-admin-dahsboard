import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_event_guard.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/number_called_schedule_patch.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/socket_payload_normalizer.dart';

GameModel _baseGame() {
  return GameModel.fromOperationJson({
    'slotId': 'slot-1',
    'sessionId': 'session-1',
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-1',
    'playerStatus': 'playing',
    'rawStatus': 'PLAYING',
    'operationMode': 'AUTO',
    'canRegister': false,
    'registrationOpen': false,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '16',
    'registeredCartelasCount': 2,
    'calledNumbersCount': 1,
    'nextAutoCallAt': '2026-06-10T12:00:00.000Z',
    'autoCallIntervalMs': 7000,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

void main() {
group('normalizeSocketPayload', () {
    test('operation_updated auto_call_changed works after normalize-only path', () {
      final payload = <dynamic, dynamic>{
        'updatedReason': 'auto_call_changed',
        'sessionId': 'sess-1',
        'slotId': 'slot-1',
        'autoCallEnabled': true,
        'nextAutoCallAt': '2099-01-01T00:00:00.000Z',
        'autoCallIntervalMs': 3000,
      };
      final normalized = normalizeSocketPayload(payload);
      expect(normalized, isNotNull);
      expect(normalized!['updatedReason'], 'auto_call_changed');
    });

      test('map payload works', () {
      final normalized = normalizeSocketPayload({
        'sessionId': 'session-1',
        'order': 2,
      });

      expect(normalized, isNotNull);
      expect(normalized!['sessionId'], 'session-1');
      expect(normalized['order'], 2);
    });

    test('list map payload works', () {
      final normalized = normalizeSocketPayload([
        {'sessionId': 'session-1', 'order': 3},
      ]);

      expect(normalized, isNotNull);
      expect(normalized!['sessionId'], 'session-1');
      expect(normalized['order'], 3);
    });

    test('readSocketEntityId accepts id and broadcastId', () {
      expect(readSocketEntityId({'id': 'broadcast-1'}), 'broadcast-1');
      expect(readSocketEntityId({'broadcastId': 'broadcast-2'}), 'broadcast-2');
      expect(readSocketEntityId({'id': ''}), isNull);
      expect(readSocketEntityId({}), isNull);
    });

    test('invalid payload triggers refresh handler', () {
      var refreshTriggered = false;
      final debugMessages = <String>[];

      final normalized = normalizeSocketPayloadOrHandleInvalid(
        'bad-payload',
        eventName: 'game:number_called',
        debugLog: debugMessages.add,
        onInvalid: () => refreshTriggered = true,
      );

      expect(normalized, isNull);
      expect(refreshTriggered, isTrue);
      expect(debugMessages.single, contains('game:number_called'));
    });

    test('json decoded map payload works (_JsonMap)', () {
      final decoded = jsonDecode(
        '{"sessionId":"session-1","status":"PLAYING"}',
      );

      final normalized = normalizeSocketPayload(decoded);

      expect(normalized, isNotNull);
      expect(normalized!['sessionId'], 'session-1');
      expect(normalized['status'], 'PLAYING');
    });

    test('json encodable legacy-like payload normalizes without crash', () {
      final normalized = normalizeSocketPayload(
        _JsonEncodableLegacySim({
          'sessionId': 'session-1',
          'status': 'FINISHED',
        }),
      );

      expect(normalized, isNotNull);
      expect(normalized!['status'], 'FINISHED');
    });
  });

  group('patchGameFromNumberCalledPayload', () {
    test('updates nextAutoCallAt and interval from socket payload', () {
      final game = _baseGame();
      final patch = patchGameFromNumberCalledPayload(game, {
        'sessionId': 'session-1',
        'nextAutoCallAt': '2026-06-10T12:00:07.000Z',
        'autoCallIntervalMs': 8000,
        'autoCallEnabled': true,
      });

      expect(patch.scheduleChanged, isTrue);
      expect(patch.autoCallEnabled, isTrue);
      expect(patch.game.nextAutoCallAt, isNotNull);
      expect(patch.game.autoCallIntervalMs, 8000);
    });

    test('leaves schedule unchanged when payload omits schedule keys', () {
      final game = _baseGame();
      final patch = patchGameFromNumberCalledPayload(game, {
        'sessionId': 'session-1',
        'order': 2,
        'number': 15,
        'letter': 'B',
      });

      expect(patch.scheduleChanged, isFalse);
      expect(patch.game.nextAutoCallAt, game.nextAutoCallAt);
      expect(patch.game.autoCallIntervalMs, game.autoCallIntervalMs);
    });

    test('accepts list payload by normalizing the first map entry', () {
      final game = _baseGame();
      final patch = patchGameFromNumberCalledPayload(game, [
        {
          'sessionId': 'session-1',
          'nextAutoCallAt': '2026-06-10T12:00:07.000Z',
          'autoCallIntervalMs': 8000,
          'autoCallEnabled': true,
        },
      ]);

      expect(patch.scheduleChanged, isTrue);
      expect(patch.game.nextAutoCallAt, isNotNull);
      expect(patch.game.autoCallIntervalMs, 8000);
    });

    test('invalid payload does not crash and leaves schedule unchanged', () {
      final game = _baseGame();
      final patch = patchGameFromNumberCalledPayload(game, 'bad-payload');

      expect(patch.scheduleChanged, isFalse);
      expect(patch.autoCallEnabled, isNull);
      expect(patch.game.nextAutoCallAt, game.nextAutoCallAt);
      expect(patch.game.autoCallIntervalMs, game.autoCallIntervalMs);
    });

    test('clears nextAutoCallAt when auto-call stops after final ball', () {
      final game = _baseGame();
      final patch = patchGameFromNumberCalledPayload(game, {
        'sessionId': 'session-1',
        'order': 75,
        'autoCallEnabled': false,
        'nextAutoCallAt': null,
      });

      expect(patch.scheduleChanged, isTrue);
      expect(patch.autoCallEnabled, isFalse);
      expect(patch.game.nextAutoCallAt, isNull);
    });
  });

  group('event guard for number_called', () {
    test('old session payload does not affect current game', () {
      final game = _baseGame();

      final affects = eventAffectsCurrentGame(
        game: game,
        activeSessionId: game.sessionId,
        eventSessionId: 'other-session',
        eventSlotId: 'slot-1',
      );

      expect(affects, isFalse);
    });
  });
}

class _JsonEncodableLegacySim {
  _JsonEncodableLegacySim(this.data);

  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => data;
}
