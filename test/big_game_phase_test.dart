import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/routing/auth_route_guard.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_game_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/big_game_countdown.dart';

void main() {
  final now = DateTime.utc(2026, 7, 1, 8);

  GameModel bigGame({
    GameStatus status = GameStatus.ready,
    DateTime? registrationOpensAt,
    DateTime? scheduledStartAt,
    String? sessionId = 'session-big-1',
  }) {
    return GameModel(
      id: 'slot-big-1',
      sessionId: sessionId,
      staticCode: 'BIG',
      playCode: '777',
      name: 'Big Game',
      gameRule: null,
      gameType: 'FULL_HOUSE',
      entryFee: '50.00',
      prizePerCartela: '0',
      companyFeePerCartela: '0',
      prizeAmount: '5000.00',
      companyRevenue: '0',
      status: status,
      playOrder: 1,
      startedAt: null,
      finishedAt: null,
      createdAt: now,
      updatedAt: now,
      registeredCartelasCount: 0,
      calledNumbersCount: 0,
      registrationOpen: true,
      canRegister: true,
      scheduledStartAt: scheduledStartAt ?? DateTime.utc(2026, 7, 1, 12),
      registrationOpensAt:
          registrationOpensAt ?? DateTime.utc(2026, 7, 1, 9),
      category: GameCategory.bigGame,
      fixedPrizeAmount: '5000.00',
      maxCartelasPerPlayer: 20,
    );
  }

  group('resolveBigGamePhase', () {
    test('returns none-equivalent before registration opens', () {
      final game = bigGame(
        registrationOpensAt: DateTime.utc(2026, 7, 1, 10),
        scheduledStartAt: DateTime.utc(2026, 7, 1, 12),
      );

      expect(
        resolveBigGamePhase(game, now: now),
        BigGamePhase.beforeRegistrationOpens,
      );
    });

    test('returns registrationOpen during registration window', () {
      final game = bigGame(
        registrationOpensAt: DateTime.utc(2026, 7, 1, 7),
        scheduledStartAt: DateTime.utc(2026, 7, 1, 12),
      );

      expect(
        resolveBigGamePhase(game, now: DateTime.utc(2026, 7, 1, 10)),
        BigGamePhase.registrationOpen,
      );
    });

    test('returns waitingToPlay after scheduled start while still ready', () {
      final game = bigGame(
        status: GameStatus.ready,
        registrationOpensAt: DateTime.utc(2026, 7, 1, 7),
        scheduledStartAt: DateTime.utc(2026, 7, 1, 9),
      );

      expect(
        resolveBigGamePhase(game, now: DateTime.utc(2026, 7, 1, 10)),
        BigGamePhase.waitingToPlay,
      );
    });

    test('returns live for playing status', () {
      final game = bigGame(status: GameStatus.playing);

      expect(
        resolveBigGamePhase(game, now: DateTime.utc(2026, 7, 1, 13)),
        BigGamePhase.live,
      );
    });

    test('returns finishedReview for finished status', () {
      final game = bigGame(status: GameStatus.finished);

      expect(
        resolveBigGamePhase(game, now: now),
        BigGamePhase.finishedReview,
      );
    });

    test('returns cancelled for cancelled status', () {
      final game = bigGame(status: GameStatus.cancelled);

      expect(
        resolveBigGamePhase(game, now: now),
        BigGamePhase.cancelled,
      );
    });
  });

  group('announcement banner phases', () {
    bool shouldShowBanner(BigGamePhase phase) {
      return switch (phase) {
        BigGamePhase.beforeRegistrationOpens ||
        BigGamePhase.registrationOpen ||
        BigGamePhase.waitingToPlay ||
        BigGamePhase.live => true,
        _ => false,
      };
    }

    test('shows banner for scheduled, waiting, and live phases', () {
      expect(
        shouldShowBanner(BigGamePhase.beforeRegistrationOpens),
        isTrue,
      );
      expect(shouldShowBanner(BigGamePhase.registrationOpen), isTrue);
      expect(shouldShowBanner(BigGamePhase.waitingToPlay), isTrue);
      expect(shouldShowBanner(BigGamePhase.live), isTrue);
      expect(shouldShowBanner(BigGamePhase.finishedReview), isFalse);
      expect(shouldShowBanner(BigGamePhase.cancelled), isFalse);
      expect(shouldShowBanner(BigGamePhase.none), isFalse);
    });

    test('waitingToPlay resolves after scheduled start while ready', () {
      final game = bigGame(
        status: GameStatus.ready,
        registrationOpensAt: DateTime.utc(2026, 7, 1, 7),
        scheduledStartAt: DateTime.utc(2026, 7, 1, 9),
      );

      expect(
        resolveBigGamePhase(game, now: DateTime.utc(2026, 7, 1, 10)),
        BigGamePhase.waitingToPlay,
      );
      expect(
        shouldShowBanner(
          resolveBigGamePhase(game, now: DateTime.utc(2026, 7, 1, 10)),
        ),
        isTrue,
      );
    });
  });

  group('formatBigGameCountdown', () {
    final now = DateTime(2026, 6, 1, 12, 0, 0);

    test('formats month-scale durations without minutes or seconds', () {
      final target = now.add(const Duration(days: 53, hours: 12));
      expect(
        formatBigGameCountdown(target, now: now),
        '1 month 23 days 12 hours',
      );
    });

    test('formats multi-day durations without seconds', () {
      final target = now.add(const Duration(days: 1, hours: 23, minutes: 12));
      expect(
        formatBigGameCountdown(target, now: now),
        '1 day 23 hours 12 mins',
      );
    });

    test('formats hour-minute-second durations', () {
      final target = now.add(const Duration(hours: 1, minutes: 34, seconds: 23));
      expect(
        formatBigGameCountdown(target, now: now),
        '1h 34 mins 23 secs',
      );
    });

    test('formats minute-second durations under one hour', () {
      final target = now.add(const Duration(minutes: 14, seconds: 10));
      expect(
        formatBigGameCountdown(target, now: now),
        '14 mins 10 secs',
      );
    });
  });

  group('auth route guard', () {
    test('big game route is protected from guests', () {
      expect(isProtectedLocation('/games/big-game'), isTrue);
      expect(kGuestLocations.contains('/games/big-game'), isFalse);
    });
  });
}
