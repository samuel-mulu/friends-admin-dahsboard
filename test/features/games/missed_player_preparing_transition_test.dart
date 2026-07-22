import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';

GameModel _ready({
  required DateTime? scheduledStartAt,
  bool canRegister = true,
}) {
  final now = DateTime.utc(2026, 7, 22, 12);
  return GameModel(
    id: 'id-b',
    sessionId: 'b',
    staticCode: 'B1',
    playCode: 'PB1',
    name: 'Game B',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '0',
    companyRevenue: '0',
    status: GameStatus.ready,
    playOrder: 2,
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: true,
    canRegister: canRegister,
    scheduledStartAt: scheduledStartAt,
  );
}

void main() {
  group('registrationCountdownElapsed after blocking live clears', () {
    test('past scheduledStartAt with canRegister stays not elapsed', () {
      final now = DateTime.utc(2026, 7, 22, 12);
      final game = _ready(
        scheduledStartAt: now.subtract(const Duration(seconds: 20)),
      );

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: const Duration(seconds: 45),
          now: now,
          blockingLiveGameExists: false,
        ),
        isFalse,
      );

      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: false,
          canonicalRefetchInFlight: false,
          calledNumbers: const [],
          staleAfter: const Duration(seconds: 45),
          blockingLiveGameExists: false,
        ),
        LivePresentationPhase.registrationOpen,
      );
    });
  });
}
