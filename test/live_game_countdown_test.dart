import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';

GameModel _playingGameWithoutNextCall() {
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
  test('liveWaitingFirstBall without nextAutoCallAt uses waiting copy', () {
    final game = _playingGameWithoutNextCall();

    final phase = LivePresentationPhaseResolver.resolve(
      game: game,
      registrationCountdownClosed: false,
      canonicalRefetchInFlight: false,
      calledNumbers: const [],
      staleAfter: const Duration(seconds: 45),
    );

    expect(phase, LivePresentationPhase.liveWaitingFirstBall);
    expect(game.nextAutoCallAt, isNull);
  });
}
