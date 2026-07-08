import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_registration_target.dart';

void main() {
  group('Phase A: resolvePrimaryRegistrationTarget', () {
    test('current playing + owned cartelas -> stay on current game', () {
      final currentGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.playing,
        canRegister: false,
      );
      final nextGame = _buildGame(
        id: 'slot-2',
        sessionId: 'session-2',
        status: GameStatus.next,
        canRegister: true,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: currentGame,
        nextUpcomingGame: nextGame,
        hasCurrentCartelas: true,
      );

      expect(target?.id, equals('slot-1'),
          reason: 'Playing + owned cartelas must not jump to NEXT.');
    });

    test('current ready/registration-open -> target current game', () {
      final currentGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.ready,
        canRegister: true,
      );
      final nextGame = _buildGame(
        id: 'slot-2',
        sessionId: 'session-2',
        status: GameStatus.next,
        canRegister: true,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: currentGame,
        nextUpcomingGame: nextGame,
        hasCurrentCartelas: true,
      );

      expect(target?.id, equals('slot-1'),
          reason: 'READY registration remains the primary target.');
    });

    test('no current ready + queue NEXT -> no registration target', () {
      final currentGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.playing,
        canRegister: false,
      );
      final nextGame = _buildGame(
        id: 'slot-2',
        sessionId: 'session-2',
        status: GameStatus.next,
        canRegister: true,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: currentGame,
        nextUpcomingGame: nextGame,
        hasCurrentCartelas: false,
      );

      expect(target, isNull,
          reason: 'Queue NEXT is not registerable by status alone.');
    });

    test('no current game + queue NEXT -> no registration target', () {
      final nextGame = _buildGame(
        id: 'slot-2',
        sessionId: 'session-2',
        status: GameStatus.next,
        canRegister: true,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: null,
        nextUpcomingGame: nextGame,
        hasCurrentCartelas: false,
      );

      expect(target, isNull);
    });

    test('no current game + READY canRegister true candidate -> target READY', () {
      final readyCandidate = _buildGame(
        id: 'slot-3',
        sessionId: 'session-3',
        status: GameStatus.ready,
        canRegister: true,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: null,
        nextUpcomingGame: readyCandidate,
        hasCurrentCartelas: false,
      );

      expect(target?.id, equals('slot-3'));
    });

    test('otherwise -> no registration target', () {
      final currentGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.playing,
        canRegister: false,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: currentGame,
        nextUpcomingGame: null,
        hasCurrentCartelas: false,
      );

      expect(target, isNull);
    });

    test('category-agnostic: Normal and Bonus produce same target', () {
      final normalGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.ready,
        canRegister: true,
        category: GameCategory.normal,
      );
      final bonusGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.ready,
        canRegister: true,
        category: GameCategory.bonus,
      );
      final bigGame = _buildGame(
        id: 'slot-1',
        sessionId: 'session-1',
        status: GameStatus.ready,
        canRegister: true,
        category: GameCategory.bigGame,
      );

      final normalTarget = resolvePrimaryRegistrationTarget(
        currentGame: normalGame,
        nextUpcomingGame: null,
        hasCurrentCartelas: false,
      );

      final bonusTarget = resolvePrimaryRegistrationTarget(
        currentGame: bonusGame,
        nextUpcomingGame: null,
        hasCurrentCartelas: false,
      );

      final bigGameTarget = resolvePrimaryRegistrationTarget(
        currentGame: bigGame,
        nextUpcomingGame: null,
        hasCurrentCartelas: false,
      );

      expect(normalTarget?.id, equals(bonusTarget?.id));
      expect(normalTarget?.id, equals(bigGameTarget?.id));
      expect(normalTarget?.id, equals('slot-1'),
          reason:
              'Category does not affect round selection; all categories produce the same target');
    });
  });
}

GameModel _buildGame({
  required String id,
  String? sessionId,
  required GameStatus status,
  required bool canRegister,
  GameCategory category = GameCategory.normal,
}) {
  return GameModel(
    id: id,
    sessionId: sessionId,
    staticCode: 'TEST',
    playCode: sessionId != null ? 'PLAY' : null,
    name: 'Test Game',
    gameRule: null,
    gameType: 'TEST',
    entryFee: '10',
    prizePerCartela: '5',
    companyFeePerCartela: '1',
    prizeAmount: '100',
    companyRevenue: '20',
    status: status,
    playOrder: 1,
    startedAt: null,
    finishedAt: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    registeredCartelasCount: 0,
    calledNumbersCount: 0,
    registrationOpen: canRegister,
    canRegister: canRegister,
    category: category,
  );
}
