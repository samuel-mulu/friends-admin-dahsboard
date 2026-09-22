import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_game_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/big_game_live_presentation.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_embedded_operations_snapshot.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';

final _now = DateTime.parse('2026-09-08T12:00:00.000Z');

GameModel _bigGameReady({
  bool canRegister = false,
  DateTime? registrationOpensAt,
  DateTime? scheduledStartAt,
}) {
  return GameModel(
    id: 'slot-1',
    sessionId: 'session-bg',
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
    status: GameStatus.ready,
    playOrder: 1,
    startedAt: null,
    finishedAt: null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 0,
    calledNumbersCount: 0,
    registrationOpen: canRegister,
    canRegister: canRegister,
    registrationOpensAt: registrationOpensAt,
    scheduledStartAt: scheduledStartAt,
    category: GameCategory.bigGame,
    roundCount: 3,
    roundIndex: 1,
  );
}

GameOperationsCurrentResponse _ops({required GameModel primary}) {
  return GameOperationsCurrentResponse(
    liveGame: primary,
    checkingGame: null,
    registrationOpenGame: primary.status == GameStatus.ready ? primary : null,
    queue: const [],
    timestamp: _now,
    serverNow: _now,
  );
}

void main() {
  group('embedded Big Game registration target', () {
    test('targets primary when window open but canRegister is false', () {
      final game = _bigGameReady(
        canRegister: false,
        registrationOpensAt: _now.subtract(const Duration(minutes: 5)),
        scheduledStartAt: _now.add(const Duration(minutes: 3)),
      );
      expect(isBigGameRegistrationWindowOpen(game, now: _now), isTrue);

      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _ops(primary: game),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: _now,
          embeddedBigGame: true,
          excludeBigGame: false,
          holds: const LiveSessionHolds(registrationGridReady: true),
        ),
      );

      expect(state.registrationTarget?.sessionId, 'session-bg');
      expect(state.useRegistrationOpenLayout, isTrue);
    });

    test('standard /games keeps canRegister-only registration target', () {
      final game = _bigGameReady(
        canRegister: false,
        registrationOpensAt: _now.subtract(const Duration(minutes: 5)),
        scheduledStartAt: _now.add(const Duration(minutes: 3)),
      );

      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _ops(primary: game),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: _now,
          embeddedBigGame: false,
          excludeBigGame: true,
        ),
      );

      expect(state.registrationTarget, isNull);
      expect(state.mode, LiveUiMode.empty);
    });
  });

  group('embedded Big Game local operations snapshot', () {
    test('READY with open window but canRegister false is registration-open', () {
      final game = _bigGameReady(
        canRegister: false,
        registrationOpensAt: _now.subtract(const Duration(minutes: 5)),
        scheduledStartAt: _now.add(const Duration(minutes: 3)),
      );
      final ops = localOperationsSnapshotForGame(game, serverNow: _now);
      expect(ops.hasActiveGame, isTrue);
      expect(ops.registrationOpenGame?.sessionId, 'session-bg');
      expect(ops.liveGame, isNull);
    });
  });

  group('embedded Big Game UI when global ops still has another live game', () {
    test('registration layout when ops aligned to embedded Big Game card', () {
      final game = _bigGameReady(
        canRegister: false,
        registrationOpensAt: _now.subtract(const Duration(minutes: 5)),
        scheduledStartAt: _now.add(const Duration(minutes: 3)),
      );
      final staleLive = GameModel(
        id: 'other-slot',
        sessionId: 'other-session',
        staticCode: 'CH-1',
        playCode: 'PLAY-2',
        name: 'Chain',
        gameRule: null,
        gameType: 'ONE_LINE',
        entryFee: '10',
        prizePerCartela: '0',
        companyFeePerCartela: '10',
        prizeAmount: '100',
        companyRevenue: '0',
        status: GameStatus.playing,
        playOrder: 1,
        startedAt: _now,
        finishedAt: null,
        createdAt: _now,
        updatedAt: _now,
        registeredCartelasCount: 1,
        calledNumbersCount: 10,
        registrationOpen: false,
        canRegister: false,
        category: GameCategory.chainGame,
      );
      final aligned = localOperationsSnapshotForGame(game, serverNow: _now);

      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: aligned,
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: _now,
          embeddedBigGame: true,
          excludeBigGame: false,
          holds: const LiveSessionHolds(registrationGridReady: true),
        ),
      );

      expect(state.useRegistrationOpenLayout, isTrue);
      expect(state.showRegistrationGrid, isTrue);
      expect(state.registrationTarget?.sessionId, 'session-bg');

      final blocked = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: GameOperationsCurrentResponse(
            liveGame: staleLive,
            checkingGame: null,
            registrationOpenGame: null,
            queue: const [],
            timestamp: _now,
            serverNow: _now,
          ),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: _now,
          embeddedBigGame: true,
          excludeBigGame: false,
          holds: const LiveSessionHolds(registrationGridReady: true),
        ),
      );
      expect(blocked.useRegistrationOpenLayout, isFalse);
      expect(blocked.registrationTarget, isNull);
    });
  });

  group('embedded Big Game empty-state suppression', () {
    test('suppresses while initial private hydration is in flight', () {
      expect(
        shouldSuppressEmbeddedBigGameEmptyCartelaState(
          embeddedBigGame: true,
          isGuest: false,
          hasPrimarySessionCartelas: false,
          initialLoadComplete: false,
          isLoading: false,
          resumeSyncInFlight: false,
          canonicalRefetchInFlight: false,
        ),
        isTrue,
      );
    });

    test('does not suppress after load completes with no cartelas', () {
      expect(
        shouldSuppressEmbeddedBigGameEmptyCartelaState(
          embeddedBigGame: true,
          isGuest: false,
          hasPrimarySessionCartelas: false,
          initialLoadComplete: true,
          isLoading: false,
          resumeSyncInFlight: false,
          canonicalRefetchInFlight: false,
        ),
        isFalse,
      );
    });

    test('never suppresses on standard embedded=false path', () {
      expect(
        shouldSuppressEmbeddedBigGameEmptyCartelaState(
          embeddedBigGame: false,
          isGuest: false,
          hasPrimarySessionCartelas: false,
          initialLoadComplete: false,
          isLoading: true,
          resumeSyncInFlight: true,
          canonicalRefetchInFlight: true,
        ),
        isFalse,
      );
    });
  });
}
