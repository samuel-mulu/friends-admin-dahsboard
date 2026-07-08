import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/current_big_game_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/big_game_screen.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final anchor = DateTime.utc(2026, 7, 1, 8);

  GameModel bigGame({
    GameStatus status = GameStatus.ready,
    DateTime? registrationOpensAt,
    DateTime? scheduledStartAt,
    List<RegisteredCartelaSummary>? registeredCartelasSummary,
  }) {
    return GameModel(
      id: 'slot-big-1',
      sessionId: 'session-big-1',
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
      createdAt: anchor,
      updatedAt: anchor,
      registeredCartelasCount: 1,
      calledNumbersCount: 0,
      registrationOpen: true,
      canRegister: true,
      scheduledStartAt: scheduledStartAt ?? DateTime.utc(2026, 7, 1, 12),
      registrationOpensAt:
          registrationOpensAt ?? DateTime.utc(2026, 7, 1, 9),
      category: GameCategory.bigGame,
      fixedPrizeAmount: '5000.00',
      maxCartelasPerPlayer: 20,
      registeredCartelasSummary: registeredCartelasSummary,
    );
  }

  Widget wrap({
    required Widget child,
    overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        localeProvider.overrideWith(_EnglishLocaleController.new),
        gamesRepositoryProvider.overrideWithValue(_FakeGamesRepository()),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows empty state when no Big Game is scheduled', (tester) async {
    await tester.pumpWidget(
      wrap(
        overrides: [
          currentBigGameProvider.overrideWith(
            () => _StaticBigGameNotifier(null),
          ),
        ],
        child: const BigGameScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Big Game scheduled yet.'), findsOneWidget);
    expect(find.text('Check back soon.'), findsOneWidget);
  });

  testWidgets('shows registration countdown before registration opens', (
    tester,
  ) async {
    final game = bigGame(
      registrationOpensAt: DateTime.utc(2026, 7, 1, 10),
      scheduledStartAt: DateTime.utc(2026, 7, 1, 12),
    );

    await tester.pumpWidget(
      wrap(
        overrides: [
          currentBigGameProvider.overrideWith(
            () => _StaticBigGameNotifier(game),
          ),
        ],
        child: const BigGameScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Big Game Scheduled'), findsOneWidget);
    expect(find.text('Registration opens in:'), findsOneWidget);
    expect(find.text('Fixed Prize'), findsOneWidget);
    expect(find.textContaining('5000'), findsWidgets);
  });

  testWidgets('registration open shows schedule banner and embeds live game', (
    tester,
  ) async {
    final game = bigGame(
      registrationOpensAt: DateTime.utc(2026, 7, 1, 7),
      scheduledStartAt: DateTime.utc(2026, 7, 1, 12),
    );

    await tester.pumpWidget(
      wrap(
        overrides: [
          currentBigGameProvider.overrideWith(
            () => _StaticBigGameNotifier(game),
          ),
        ],
        child: const BigGameScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Big Game Registration Open'), findsOneWidget);
    expect(find.text('Play starts in:'), findsOneWidget);
    expect(find.text('Fixed Prize'), findsOneWidget);
    expect(find.textContaining('5000'), findsWidgets);
  });

  testWidgets('waiting state hides registration and shows your cartelas', (
    tester,
  ) async {
    final game = bigGame(
      status: GameStatus.ready,
      registrationOpensAt: DateTime.utc(2026, 7, 1, 7),
      scheduledStartAt: DateTime.utc(2026, 7, 1, 8),
      registeredCartelasSummary: const [
        RegisteredCartelaSummary(
          cartelaId: 'c-1',
          cartelaNumber: 42,
          owner: 'ME',
          status: 'REGISTERED',
        ),
      ],
    );

    await tester.pumpWidget(
      wrap(
        overrides: [
          currentBigGameProvider.overrideWith(
            () => _StaticBigGameNotifier(game),
          ),
        ],
        child: const BigGameScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Big Game is ready'), findsOneWidget);
    expect(find.text('Waiting for current round to finish.'), findsOneWidget);
    expect(find.text('Your Cartelas'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget);
    expect(find.text('Big Game Registration Open'), findsNothing);
  });
}

class _EnglishLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

class _StaticBigGameNotifier extends CurrentBigGameNotifier {
  _StaticBigGameNotifier(this.value);

  final GameModel? value;

  @override
  Future<GameModel?> build() async => value;
}

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository() : super(ApiClient(Dio()));

  @override
  Future<GameTimingConfigModel> getTimeConfig() async {
    return GameTimingConfigModel(
      registrationDurationSeconds:
          GameTimingConfigModel.defaultRegistrationDurationSeconds,
      autoCallIntervalSeconds:
          GameTimingConfigModel.defaultAutoCallIntervalSeconds,
      winnerWindowSeconds: GameTimingConfigModel.defaultWinnerWindowSeconds,
      cartelaHoldSeconds: GameTimingConfigModel.defaultCartelaHoldSeconds,
      bulkSelectionHoldSeconds:
          GameTimingConfigModel.defaultBulkSelectionHoldSeconds,
      finishedResultDisplaySeconds:
          GameTimingConfigModel.defaultFinishedResultDisplaySeconds,
      winningPatternDisplaySeconds:
          GameTimingConfigModel.defaultWinningPatternDisplaySeconds,
      preparingDisplayMaxSeconds: null,
      missedNumberAnimationMs:
          GameTimingConfigModel.defaultMissedNumberAnimationMs,
      missedNumberStaggerMaxBalls:
          GameTimingConfigModel.defaultMissedNumberStaggerMaxBalls,
      flutterRefetchDebounceMs:
          GameTimingConfigModel.defaultFlutterRefetchDebounceMs,
      serverNow: DateTime.utc(2026, 7, 1, 8),
    );
  }
}
