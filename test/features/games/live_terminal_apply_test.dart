import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_terminal_apply.dart';

GameModel _session({
  required GameStatus status,
  bool chain = true,
}) {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');
  return GameModel(
    id: 'slot-1',
    sessionId: 'session-1',
    staticCode: 'CH-1',
    playCode: 'PLAY-1',
    name: 'Chain',
    gameRule: null,
    gameType: 'ONE_LINE',
    entryFee: '10',
    prizePerCartela: '0',
    companyFeePerCartela: '10',
    prizeAmount: '100',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: status == GameStatus.finished ? now : null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 10,
    registrationOpen: false,
    canRegister: false,
    category: chain ? GameCategory.chainGame : GameCategory.normal,
    roundCount: 2,
    roundIndex: 2,
  );
}

void main() {
  group('shouldClampStaleWinnerWindowOnCanonicalApply', () {
    test('clamps when post-game summary active and incoming winnerWindow', () {
      final previous = _session(status: GameStatus.winnerWindow);
      final incoming = _session(status: GameStatus.winnerWindow);
      expect(
        shouldClampStaleWinnerWindowOnCanonicalApply(
          resumeSync: false,
          previousGame: previous,
          incoming: incoming,
          postGameSummaryReviewActive: true,
        ),
        isTrue,
      );
    });

    test('clamps when chain local finished and incoming winnerWindow', () {
      final previous = _session(status: GameStatus.finished);
      final incoming = _session(status: GameStatus.winnerWindow);
      expect(
        shouldClampStaleWinnerWindowOnCanonicalApply(
          resumeSync: false,
          previousGame: previous,
          incoming: incoming,
          postGameSummaryReviewActive: false,
        ),
        isTrue,
      );
    });
  });

  group('mergeCanonicalSessionState terminal guard', () {
    test('keeps finished when incoming winnerWindow', () {
      final current = _session(status: GameStatus.finished);
      final incoming = _session(status: GameStatus.winnerWindow);
      final merged = GameModel.mergeCanonicalSessionState(
        current: current,
        incoming: incoming,
      );
      expect(merged.status, GameStatus.finished);
      expect(merged.winnerWindowEndsAt, isNull);
    });
  });

  group('presentation phase during post-game summary', () {
    test('winnerWindow status maps to review when summary active', () {
      final game = _session(status: GameStatus.winnerWindow, chain: false);
      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const [],
          staleAfter: const Duration(seconds: 45),
          postGameSummaryReviewActive: true,
        ),
        LivePresentationPhase.review,
      );
    });
  });
}
