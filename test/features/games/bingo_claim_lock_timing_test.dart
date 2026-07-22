import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_countdown.dart';

void main() {
  final now = DateTime.utc(2026, 7, 22, 12, 0, 0);

  group('resolveNextBallPlayPhase', () {
    test('locks in the last 1 second before auto-call', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(milliseconds: 1000)),
          now: now,
        ),
        NextBallPlayPhase.preCallLocked,
      );
    });

    test('stays counting when more than 1 second remains', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(milliseconds: 1001)),
          now: now,
        ),
        NextBallPlayPhase.counting,
      );
    });
  });

  group('isBingoClaimCountdownLocked', () {
    test('locks during pre-call window', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('locks while awaiting the called ball', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.subtract(const Duration(milliseconds: 50)),
          now: now,
          playPhase: NextBallPlayPhase.calling,
          highestKnownCalledOrder: 3,
          callingPhaseBaselineOrder: 3,
        ),
        isTrue,
      );
    });

    test('locks during post-call hold after ball arrives', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 5)),
          now: now,
          playPhase: NextBallPlayPhase.counting,
          highestKnownCalledOrder: 4,
          callingPhaseBaselineOrder: null,
          postCallLockUntil: now.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('unlocks after post-call hold expires', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 5)),
          now: now,
          playPhase: NextBallPlayPhase.counting,
          highestKnownCalledOrder: 4,
          postCallLockUntil: now,
        ),
        isFalse,
      );
    });

    test('post-call hold wins even when nextAutoCallAt is briefly null', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: null,
          now: now,
          postCallLockUntil: now.add(const Duration(milliseconds: 500)),
        ),
        isTrue,
      );
    });
  });

  group('isBingoPostCallHoldActive', () {
    test('is active before unlock instant', () {
      expect(
        isBingoPostCallHoldActive(
          postCallLockUntil: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('is inactive at or after unlock instant', () {
      expect(
        isBingoPostCallHoldActive(
          postCallLockUntil: now,
          now: now,
        ),
        isFalse,
      );
    });
  });

  test('constants match requested 1s pre-call and 1s post-call timing', () {
    expect(kBingoClaimLockSeconds, 1);
    expect(kBingoClaimPostCallUnlockSeconds, 1);
  });
}
