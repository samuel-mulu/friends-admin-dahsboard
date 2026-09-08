import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_game_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';

GameModel _bigGame({
  required GameStatus status,
  required bool canRegister,
  DateTime? registrationOpensAt,
  DateTime? scheduledStartAt,
  int roundIndex = 1,
}) {
  final now = DateTime.parse('2026-09-08T12:00:00.000Z');
  return GameModel(
    id: 'slot-1',
    sessionId: 'session-1',
    staticCode: 'BG-1',
    playCode: 'PLAY-1',
    name: 'Big Game',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '50',
    prizePerCartela: '40',
    companyFeePerCartela: '10',
    prizeAmount: '1000',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: 0,
    registrationOpen: canRegister,
    canRegister: canRegister,
    registrationOpensAt: registrationOpensAt,
    scheduledStartAt: scheduledStartAt,
    category: GameCategory.bigGame,
    roundCount: 3,
    roundIndex: roundIndex,
  );
}

void main() {
  final now = DateTime.parse('2026-09-08T12:00:00.000Z');

  group('Big Game registration window / phase alignment', () {
    test('banner stays open only while play window is open', () {
      final game = _bigGame(
        status: GameStatus.ready,
        canRegister: false,
        registrationOpensAt: now.subtract(const Duration(minutes: 5)),
        scheduledStartAt: now.add(const Duration(minutes: 2)),
      );

      expect(isBigGameRegistrationWindowOpen(game, now: now), isTrue);
      expect(resolveBigGamePhase(game, now: now), BigGamePhase.registrationOpen);
    });

    test('banner is not open when play start has passed', () {
      final game = _bigGame(
        status: GameStatus.ready,
        canRegister: false,
        registrationOpensAt: now.subtract(const Duration(minutes: 10)),
        scheduledStartAt: now.subtract(const Duration(seconds: 1)),
      );

      expect(isBigGameRegistrationWindowOpen(game, now: now), isFalse);
      expect(resolveBigGamePhase(game, now: now), BigGamePhase.waitingToPlay);
    });

    test('live presentation stays registrationOpen while Big Game window is open', () {
      final game = _bigGame(
        status: GameStatus.ready,
        canRegister: false,
        registrationOpensAt: now.subtract(const Duration(minutes: 5)),
        scheduledStartAt: now.add(const Duration(minutes: 1)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: const Duration(seconds: 45),
        now: now,
      );

      expect(phase, LivePresentationPhase.registrationOpen);
    });

    test('open-ended next-round window (null scheduledStartAt) stays open', () {
      final game = _bigGame(
        status: GameStatus.ready,
        canRegister: true,
        registrationOpensAt: now.subtract(const Duration(minutes: 1)),
        scheduledStartAt: null,
        roundIndex: 2,
      );

      expect(isBigGameRegistrationWindowOpen(game, now: now), isTrue);
      expect(resolveBigGamePhase(game, now: now), BigGamePhase.registrationOpen);
    });
  });
}
