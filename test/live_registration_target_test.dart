import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_registration_target.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/live_next_round_registration_section.dart';

GameModel _game({
  required String id,
  bool canRegister = false,
  GameStatus status = GameStatus.playing,
}) {
  final now = DateTime.utc(2026, 6, 15);
  return GameModel(
    id: id,
    sessionId: 'session-$id',
    staticCode: id,
    playCode: id,
    name: 'Game $id',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '10.00',
    prizePerCartela: '50.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: 3,
    registrationOpen: canRegister,
    canRegister: canRegister,
  );
}

void main() {
  group('resolvePrimaryRegistrationTarget', () {
    test(
      'does not target queue NEXT when live player missed current round',
      () {
        final current = _game(id: 'live', canRegister: false);
        final next = _game(
          id: 'next',
          canRegister: true,
          status: GameStatus.next,
        );

        expect(
          resolvePrimaryRegistrationTarget(
            currentGame: current,
            nextUpcomingGame: next,
            hasCurrentCartelas: false,
          ),
          isNull,
        );
      },
    );

    test('targets READY candidate when current is not registerable', () {
      final current = _game(id: 'live', canRegister: false);
      final next = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        resolvePrimaryRegistrationTarget(
          currentGame: current,
          nextUpcomingGame: next,
          hasCurrentCartelas: false,
        ),
        next,
      );
    });

    test('keeps current game when registration is still open', () {
      final current = _game(
        id: 'live',
        canRegister: true,
        status: GameStatus.ready,
      );
      final next = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        resolvePrimaryRegistrationTarget(
          currentGame: current,
          nextUpcomingGame: next,
          hasCurrentCartelas: false,
        ),
        current,
      );
    });

    test('returns null when neither current nor next registration is open', () {
      final current = _game(id: 'live', canRegister: false);

      expect(
        resolvePrimaryRegistrationTarget(
          currentGame: current,
          nextUpcomingGame: null,
          hasCurrentCartelas: false,
        ),
        isNull,
      );
    });
  });

  group('usesExpandedNoCartelaRegistrationLayout', () {
    test('is true for authenticated live player without cartelas', () {
      final target = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.next,
      );

      expect(
        usesExpandedNoCartelaRegistrationLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          showsInlinePlayCartelas: true,
          registrationTarget: target,
        ),
        isTrue,
      );
    });

    test('is true while current-session cartelas are still resolving', () {
      final target = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.next,
      );

      expect(
        usesExpandedNoCartelaRegistrationLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          showsInlinePlayCartelas: true,
          registrationTarget: target,
        ),
        isTrue,
      );
    });

    test('is false for guests', () {
      expect(
        usesExpandedNoCartelaRegistrationLayout(
          isGuest: true,
          hasCurrentCartelas: false,
          showsInlinePlayCartelas: true,
          registrationTarget: _game(id: 'next'),
        ),
        isFalse,
      );
    });
  });

  group('shouldPromoteRegistrationTargetToPrimaryLayout', () {
    test('promotes open next registration after terminal empty round', () {
      final next = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        shouldPromoteRegistrationTargetToPrimaryLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          currentPhaseIsTerminal: true,
          blocksRegistrationPromotion: false,
          registrationTargetIsCurrentGame: false,
          registrationTarget: next,
        ),
        isTrue,
      );
    });

    test('promotes while current-session cartelas are unresolved', () {
      final next = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        shouldPromoteRegistrationTargetToPrimaryLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          currentPhaseIsTerminal: true,
          blocksRegistrationPromotion: false,
          registrationTargetIsCurrentGame: false,
          registrationTarget: next,
        ),
        isTrue,
      );
    });

    test('does not promote during post-game review hold', () {
      final next = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        shouldPromoteRegistrationTargetToPrimaryLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          currentPhaseIsTerminal: true,
          blocksRegistrationPromotion: true,
          registrationTargetIsCurrentGame: false,
          registrationTarget: next,
        ),
        isFalse,
      );
    });

    test(
      'promotes during cancelled terminal even while advance hold is active',
      () {
        final next = _game(
          id: 'next',
          canRegister: true,
          status: GameStatus.ready,
        );

        expect(
          shouldPromoteRegistrationTargetToPrimaryLayout(
            isGuest: false,
            hasCurrentCartelas: false,
            currentPhaseIsTerminal: true,
            blocksRegistrationPromotion:
                blocksRegistrationPromotionDuringReview(
                  postGameSummaryReviewActive: true,
                  isPresentationReviewPhase: true,
                  gameStatus: GameStatus.cancelled,
                  winnerWindowExpired: false,
                  isCancelledTerminal: true,
                ),
            registrationTargetIsCurrentGame: false,
            registrationTarget: next,
          ),
          isTrue,
        );
      },
    );

    test('does not promote when player has current cartelas', () {
      final next = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        shouldPromoteRegistrationTargetToPrimaryLayout(
          isGuest: false,
          hasCurrentCartelas: true,
          currentPhaseIsTerminal: true,
          blocksRegistrationPromotion: false,
          registrationTargetIsCurrentGame: false,
          registrationTarget: next,
        ),
        isFalse,
      );
    });
  });

  group('missed-player scenario: PLAYING + READY + no cartelas', () {
    test(
      'READY primary game is the registration target (isCurrentRound=true)',
      () {
        final readyGame = _game(
          id: 'ready',
          canRegister: true,
          status: GameStatus.ready,
        );

        final target = resolvePrimaryRegistrationTarget(
          currentGame: readyGame,
          nextUpcomingGame: null,
          hasCurrentCartelas: false,
        );

        expect(
          target,
          same(readyGame),
          reason:
              'When _game=READY and player has no prior cartelas, '
              'the READY game is the target → isCurrentRound=true → '
              'no duplicate missed-round wrapper is shown.',
        );
      },
    );

    test('READY primary with queue NEXT still targets READY, not NEXT', () {
      final readyGame = _game(
        id: 'ready',
        canRegister: true,
        status: GameStatus.ready,
      );
      final nextGame = _game(
        id: 'next',
        canRegister: true,
        status: GameStatus.next,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: readyGame,
        nextUpcomingGame: nextGame,
        hasCurrentCartelas: false,
      );

      expect(
        target?.id,
        equals('ready'),
        reason:
            'Case 2 (READY primary) takes priority over Case 3 (next NEXT).',
      );
    });

    test('no game open state is suppressed when READY exists as primary', () {
      final readyGame = _game(
        id: 'ready',
        canRegister: true,
        status: GameStatus.ready,
      );

      final target = resolvePrimaryRegistrationTarget(
        currentGame: readyGame,
        nextUpcomingGame: null,
        hasCurrentCartelas: false,
      );

      expect(
        target,
        isNotNull,
        reason:
            'Non-null target means _game!=null → no-game-open state is never shown.',
      );
    });
  });

  group('shouldUseMissedRoundRegistrationPresentation', () {
    test(
      'uses missed-round presentation for READY behind active live game',
      () {
        final ready = _game(
          id: 'ready',
          canRegister: true,
          status: GameStatus.ready,
        );

        expect(
          shouldUseMissedRoundRegistrationPresentation(
            registrationTargetIsCurrentGame: true,
            hasBlockingLiveGame: true,
            hasCurrentCartelas: false,
            registrationTarget: ready,
          ),
          isTrue,
        );
      },
    );

    test('does not use missed-round presentation when player has cartelas', () {
      final ready = _game(
        id: 'ready',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        shouldUseMissedRoundRegistrationPresentation(
          registrationTargetIsCurrentGame: true,
          hasBlockingLiveGame: true,
          hasCurrentCartelas: true,
          registrationTarget: ready,
        ),
        isFalse,
      );
    });

    test('does not use missed-round presentation without active live game', () {
      final ready = _game(
        id: 'ready',
        canRegister: true,
        status: GameStatus.ready,
      );

      expect(
        shouldUseMissedRoundRegistrationPresentation(
          registrationTargetIsCurrentGame: true,
          hasBlockingLiveGame: false,
          hasCurrentCartelas: false,
          registrationTarget: ready,
        ),
        isFalse,
      );
    });
  });

  group('shouldDeferNextRoundRegistrationCountdown', () {
    test('does not defer when registration target IS the current game', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.liveCalling,
          registrationTargetIsCurrentGame: true,
        ),
        isFalse,
        reason:
            'Missed-player READY is _game; blocking live game defers '
            'via hideCountdown/_currentReadyCountdownDeferredByLiveGame, not here.',
      );
    });

    test('does not defer when target is current during winner window', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.winnerWindow,
          registrationTargetIsCurrentGame: true,
        ),
        isFalse,
      );
    });

    test('defers next-round countdown while balls are being called', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.liveCalling,
          registrationTargetIsCurrentGame: false,
        ),
        isTrue,
      );
    });

    test('defers next-round countdown during winner window', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.winnerWindow,
          registrationTargetIsCurrentGame: false,
        ),
        isTrue,
      );
    });

    test('defers next-round countdown during winner window closing', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.winnerWindowClosing,
          registrationTargetIsCurrentGame: false,
        ),
        isTrue,
      );
    });

    test('defers next-round countdown during checking phase', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.checking,
          registrationTargetIsCurrentGame: false,
        ),
        isTrue,
      );
    });

    test('does not defer in registration-open phase (no live blocker)', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.registrationOpen,
          registrationTargetIsCurrentGame: false,
        ),
        isFalse,
      );
    });

    test('does not defer in terminal review phase', () {
      expect(
        shouldDeferNextRoundRegistrationCountdown(
          currentPhase: LivePresentationPhase.review,
          registrationTargetIsCurrentGame: false,
        ),
        isFalse,
      );
    });
  });

  group('LiveNextRoundRegistrationSection', () {
    testWidgets('shows game name, helper, and empty registered state', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LiveNextRoundRegistrationSection(
                gameName: 'Evening Bingo',
                sectionTitle: 'Next round',
                helperText: 'Register for the next queued play.',
                registeredCartelaNumbers: const [],
                panel: const Text('panel'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Next round'), findsOneWidget);
      expect(find.text('Evening Bingo'), findsOneWidget);
      expect(find.text('Register for the next queued play.'), findsOneWidget);
      expect(find.text('None yet — pick numbers below.'), findsOneWidget);
      expect(find.text('panel'), findsOneWidget);
    });

    testWidgets('shows registered cartela chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LiveNextRoundRegistrationSection(
                gameName: 'Evening Bingo',
                sectionTitle: 'Next round',
                helperText: 'Register for the next queued play.',
                registeredCartelaNumbers: const [7, 12],
                panel: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('#7'), findsOneWidget);
      expect(find.text('#12'), findsOneWidget);
    });

    testWidgets('missed-round mode shows helper and next game name', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LiveNextRoundRegistrationSection(
                gameName: 'Late Night Bingo',
                sectionTitle: 'Next round registration',
                helperText:
                    'You missed this round. Register now for the next queued play.',
                registeredCartelaNumbers: const [],
                panel: const Text('panel'),
                currentRoundGameName: '3 Columns 1 Diagonal',
                variant: LiveNextRoundSectionVariant.missedCurrentRound,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Next round registration'), findsNothing);
      expect(find.text('Live & next round'), findsOneWidget);
      expect(find.text('Late Night Bingo'), findsNothing);
      expect(
        find.text('Missed · 3 Columns 1 Diagonal'),
        findsOneWidget,
      );
      expect(
        find.text('Next ready · Late Night Bingo · register now'),
        findsOneWidget,
      );
      expect(find.text('Next queued play'), findsNothing);
      expect(
        find.text(
          'Register cartelas now for the next game and play next round.',
        ),
        findsNothing,
      );
      expect(find.text('You missed this round.'), findsNothing);

      await tester.tap(find.text('Live & next round'));
      await tester.pumpAndSettle();

      expect(find.text('Next queued play'), findsOneWidget);
      expect(
        find.text(
          'Register cartelas now for the next game and play next round.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Current round in play'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next queued play'));
      await tester.pumpAndSettle();

      expect(find.text('3 Columns 1 Diagonal'), findsOneWidget);
      expect(find.text('You missed this round.'), findsOneWidget);
      expect(find.text('Late Night Bingo'), findsWidgets);
      expect(find.text('None yet — pick numbers below.'), findsNothing);
      expect(find.text('panel'), findsOneWidget);
    });
  });
}
