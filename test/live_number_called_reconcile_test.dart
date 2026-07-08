import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_event_guard.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';

GameModel _registrationGame({int calledNumbersCount = 0}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-1',
    'sessionId': 'session-1',
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-1',
    'playerStatus': 'registrationOpen',
    'rawStatus': 'READY',
    'operationMode': 'AUTO',
    'canRegister': true,
    'registrationOpen': true,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '0',
    'registeredCartelasCount': 0,
    'calledNumbersCount': calledNumbersCount,
    'gameRule': {
      'id': 'rule-1',
      'key': 'FULL_HOUSE',
      'name': 'Full House',
    },
  });
}

void main() {
  group('number_called reconciliation', () {
    test('registrationOpen status needs live reconcile when ball arrives', () {
      final game = _registrationGame();

      expect(isLivePlayGameStatus(game.status), isFalse);
    });

    test('promoted playing status resolves away from registration layout', () {
      final game = _registrationGame(calledNumbersCount: 1).copyWith(
        status: GameStatus.playing,
        canRegister: false,
        registrationOpen: false,
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: const Duration(seconds: 45),
      );

      expect(phase, LivePresentationPhase.liveCalling);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('calledNumbersCount alone hides registration actions', () {
      final game = _registrationGame(calledNumbersCount: 2);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: const Duration(seconds: 45),
      );

      expect(phase, LivePresentationPhase.liveCalling);
      expect(phase.isRegistrationLayout, isFalse);
    });
  });
}
