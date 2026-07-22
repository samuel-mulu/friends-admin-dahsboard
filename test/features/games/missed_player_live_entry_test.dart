import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_primary_game_selection.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_session_ownership.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_resolver.dart';

GameModel _game({
  required String sessionId,
  required GameStatus status,
  bool canRegister = false,
}) {
  final now = DateTime.utc(2026, 7, 22);
  return GameModel(
    id: 'id-$sessionId',
    sessionId: sessionId,
    staticCode: 'CODE-$sessionId',
    playCode: 'P-$sessionId',
    name: 'Game $sessionId',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '0',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: status == GameStatus.ready ? null : now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: status == GameStatus.ready,
    canRegister: canRegister,
  );
}

GameOperationsCurrentResponse _ops({
  GameModel? live,
  GameModel? registration,
}) {
  final now = DateTime.utc(2026, 7, 22);
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: null,
    registrationOpenGame: registration,
    queue: const [],
    timestamp: now,
    serverNow: now,
  );
}

void main() {
  group('Player 2 missed entry after A goes live', () {
    test(
      'patched primary=A playing + empty cartelas → not live owner → primary B',
      () {
        final a = _game(sessionId: 'a', status: GameStatus.playing);
        final b = _game(
          sessionId: 'b',
          status: GameStatus.ready,
          canRegister: true,
        );
        final ops = _ops(live: a, registration: b);

        // Simulates post status_changed patch: _game is A playing, no cartelas.
        final ownsLive = ownsLiveSessionCartelas(
          liveSessionId: a.sessionId,
          primarySessionId: a.sessionId,
          cartelaSessionIds: const [],
        );
        expect(ownsLive, isFalse);

        final primary = resolvePrimaryGameForOperations(
          operations: ops,
          ownsLiveCartelas: ownsLive,
        );
        expect(primary?.sessionId, 'b');

        final preview = resolveMissedLivePreview(
          operations: ops,
          ownsSession: (id) => ownsSessionByCartelas(id, const []),
        );
        expect(preview.showPreview, isTrue);
        expect(preview.previewSession?.sessionId, 'a');

        final ui = resolveLiveUiMode(
          ResolveLiveUiModeInput(
            operations: ops,
            ownsLiveSessionCartelas: false,
            hasPrimarySessionCartelas: false,
            calledNumbers: const [],
            holds: const LiveSessionHolds(),
            now: now,
            preparingStaleAfter: const Duration(minutes: 2),
            isGuest: false,
            isLoading: false,
            awaitingLiveRoom: false,
            hasError: false,
            winnerWindowExpired: false,
          ),
        );
        expect(ui.mode, LiveUiMode.missedRoundRegistration);
        expect(ui.showMissedRoundWrapper, isTrue);
      },
    );

    test('Player 1 with cartelas on A stays live primary', () {
      final a = _game(sessionId: 'a', status: GameStatus.playing);
      final b = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final ops = _ops(live: a, registration: b);

      final ownsLive = ownsLiveSessionCartelas(
        liveSessionId: a.sessionId,
        primarySessionId: a.sessionId,
        cartelaSessionIds: const ['a'],
      );
      expect(ownsLive, isTrue);

      final primary = resolvePrimaryGameForOperations(
        operations: ops,
        ownsLiveCartelas: ownsLive,
      );
      expect(primary?.sessionId, 'a');
    });
  });
}

final now = DateTime.utc(2026, 7, 22);
