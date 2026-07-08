import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_registration_target.dart';

void main() {
  group('shouldPinTerminalSession', () {
    test('pins finished and active review', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.finished,
          postGameSummaryReviewActive: false,
          winnerWindowExpired: false,
        ),
        isTrue,
      );
      expect(
        shouldPinTerminalSession(
          status: GameStatus.playing,
          postGameSummaryReviewActive: true,
          winnerWindowExpired: false,
        ),
        isTrue,
      );
    });

    test('pins expired winner window before finished socket arrives', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.winnerWindow,
          postGameSummaryReviewActive: false,
          winnerWindowExpired: true,
        ),
        isTrue,
      );
      expect(
        shouldPinTerminalSession(
          status: GameStatus.winnerWindow,
          postGameSummaryReviewActive: false,
          winnerWindowExpired: false,
        ),
        isFalse,
      );
    });

    test('does not pin cancelled sessions', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.cancelled,
          postGameSummaryReviewActive: false,
          winnerWindowExpired: false,
        ),
        isFalse,
      );
    });
  });

  group('blocksRegistrationPromotionDuringReview', () {
    test('blocks while post-game summary review is active', () {
      expect(
        blocksRegistrationPromotionDuringReview(
          postGameSummaryReviewActive: true,
          isPresentationReviewPhase: false,
          gameStatus: GameStatus.finished,
          winnerWindowExpired: false,
          isCancelledTerminal: false,
        ),
        isTrue,
      );
    });

    test('blocks when finished presentation phase is active', () {
      expect(
        blocksRegistrationPromotionDuringReview(
          postGameSummaryReviewActive: false,
          isPresentationReviewPhase: true,
          gameStatus: GameStatus.finished,
          winnerWindowExpired: false,
          isCancelledTerminal: false,
        ),
        isTrue,
      );
    });

    test('blocks when winner window expired locally', () {
      expect(
        blocksRegistrationPromotionDuringReview(
          postGameSummaryReviewActive: false,
          isPresentationReviewPhase: false,
          gameStatus: GameStatus.winnerWindow,
          winnerWindowExpired: true,
          isCancelledTerminal: false,
        ),
        isTrue,
      );
    });

    test('allows promotion for cancelled terminal skip', () {
      expect(
        blocksRegistrationPromotionDuringReview(
          postGameSummaryReviewActive: true,
          isPresentationReviewPhase: true,
          gameStatus: GameStatus.cancelled,
          winnerWindowExpired: false,
          isCancelledTerminal: true,
        ),
        isFalse,
      );
    });
  });

  group('registration promotion after terminal round', () {
    GameModel nextGame() {
      final now = DateTime.utc(2026, 6, 15);
      return GameModel(
        id: 'next',
        sessionId: 'session-next',
        staticCode: 'NEXT',
        playCode: 'NEXT',
        name: 'Next game',
        gameRule: null,
        gameType: 'FULL_HOUSE',
        entryFee: '10.00',
        prizePerCartela: '10.00',
        companyFeePerCartela: '1.00',
        prizeAmount: '100.00',
        companyRevenue: '10.00',
        status: GameStatus.next,
        playOrder: 2,
        startedAt: null,
        finishedAt: null,
        createdAt: now,
        updatedAt: now,
        registeredCartelasCount: 0,
        calledNumbersCount: 0,
        registrationOpen: true,
        canRegister: true,
      );
    }

    test('does not promote while finished review blocks registration', () {
      expect(
        shouldPromoteRegistrationTargetToPrimaryLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          currentPhaseIsTerminal: true,
          blocksRegistrationPromotion: blocksRegistrationPromotionDuringReview(
            postGameSummaryReviewActive: false,
            isPresentationReviewPhase: true,
            gameStatus: GameStatus.finished,
            winnerWindowExpired: false,
            isCancelledTerminal: false,
          ),
          registrationTargetIsCurrentGame: false,
          registrationTarget: nextGame(),
        ),
        isFalse,
      );
    });
  });
}
