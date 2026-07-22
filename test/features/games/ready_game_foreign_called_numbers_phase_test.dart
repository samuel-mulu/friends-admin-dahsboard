import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';

GameModel _readyGame({required String sessionId, int calledNumbersCount = 0}) {
  final now = DateTime.utc(2026, 7, 22);
  return GameModel(
    id: 'id-$sessionId',
    sessionId: sessionId,
    staticCode: 'CODE',
    playCode: 'P',
    name: 'Game',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '0',
    companyRevenue: '0',
    status: GameStatus.ready,
    playOrder: 1,
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: calledNumbersCount,
    registrationOpen: true,
    canRegister: true,
  );
}

CalledNumberModel _ball({required String sessionId, required int order}) {
  return CalledNumberModel(
    id: 'ball-$sessionId-$order',
    sessionId: sessionId,
    letter: 'B',
    number: order,
    order: order,
    createdAt: DateTime.utc(2026, 7, 22),
  );
}

void main() {
  group('readyGameIndicatesLiveCalling', () {
    test('foreign session balls do not flip READY Game B to liveCalling', () {
      final gameB = _readyGame(sessionId: 'b');
      expect(
        readyGameIndicatesLiveCalling(
          game: gameB,
          calledNumbers: [
            _ball(sessionId: 'a', order: 1),
            _ball(sessionId: 'a', order: 75),
          ],
        ),
        isFalse,
      );
    });

    test('same-session balls flip READY to liveCalling (AUTO start lag)', () {
      final gameB = _readyGame(sessionId: 'b');
      expect(
        readyGameIndicatesLiveCalling(
          game: gameB,
          calledNumbers: [_ball(sessionId: 'b', order: 1)],
        ),
        isTrue,
      );
    });

    test('calledNumbersCount on game flips READY to liveCalling', () {
      final gameB = _readyGame(sessionId: 'b', calledNumbersCount: 3);
      expect(
        readyGameIndicatesLiveCalling(
          game: gameB,
          calledNumbers: const [],
        ),
        isTrue,
      );
    });

    test('resolve stays registrationOpen when only foreign balls exist', () {
      final gameB = _readyGame(sessionId: 'b');
      final phase = LivePresentationPhaseResolver.resolve(
        game: gameB,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: [_ball(sessionId: 'a', order: 75)],
        staleAfter: const Duration(minutes: 2),
      );
      expect(phase, LivePresentationPhase.registrationOpen);
    });
  });
}
