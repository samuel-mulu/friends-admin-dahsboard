import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/core/network/pagination_meta.dart';
import 'package:friends_bingo_app/src/features/games/domain/attended_game_history_entry.dart';
import 'package:friends_bingo_app/src/features/games/domain/attended_game_history_state.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_localized_name.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/game_history_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/game_history_screen.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/game_history_detail_dialog.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/winning_pattern_cartela_grid.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/providers/locale_provider.dart';

AttendedGameHistoryEntry _historyEntry({
  String name = 'Friday Bingo',
  int cartelaNumber = 12,
  bool isWinner = false,
}) {
  final now = DateTime.utc(2026, 6, 15, 12);
  const sessionId = 'session-1';
  return AttendedGameHistoryEntry(
    game: GameModel(
      id: sessionId,
      sessionId: sessionId,
      staticCode: 'CODE',
      playCode: '123',
      name: name,
      gameRule: null,
      gameType: 'FULL_HOUSE',
      entryFee: '5.00',
      prizePerCartela: '10.00',
      companyFeePerCartela: '1.00',
      prizeAmount: '100.00',
      companyRevenue: '20.00',
      status: GameStatus.finished,
      playOrder: 1,
      startedAt: now,
      finishedAt: now,
      createdAt: now,
      updatedAt: now,
      registeredCartelasCount: 10,
      calledNumbersCount: 20,
      registrationOpen: false,
      canRegister: false,
    ),
    myCartelas: [
      GameCartelaModel(
        id: 'gc-1',
        gameId: sessionId,
        userId: 'user-1',
        cartelaId: 'cartela-1',
        status: isWinner
            ? GameCartelaStatus.winner
            : GameCartelaStatus.registered,
        isWinner: isWinner,
        blockedAt: null,
        createdAt: now,
        updatedAt: now,
        cartela: CartelaModel(
          id: 'cartela-1',
          number: cartelaNumber,
          createdAt: now,
          b: const ['1', '2', '3', '4', '5'],
          i: const ['6', '7', '8', '9', '10'],
          n: const ['11', '12', 'FREE', '14', '15'],
          g: const ['16', '17', '18', '19', '20'],
          o: const ['21', '22', '23', '24', '25'],
        ),
      ),
    ],
  );
}

class _StubHistoryNotifier extends AttendedGameHistoryNotifier {
  _StubHistoryNotifier(this.initial);

  final AttendedGameHistoryState initial;

  @override
  Future<AttendedGameHistoryState> build() async => initial;
}

AttendedGameHistoryState _historyState({
  List<AttendedGameHistoryEntry>? entries,
  bool hasMore = false,
}) {
  final resolvedEntries = entries ?? [_historyEntry()];
  return AttendedGameHistoryState(
    entries: resolvedEntries,
    pagination: PaginationMeta(
      page: 1,
      pageSize: 50,
      totalItems: resolvedEntries.length,
      totalPages: hasMore ? 2 : 1,
    ),
  );
}

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository({required this.winnerResults})
      : super(ApiClient(Dio()));

  final List<SessionWinnerResultModel> winnerResults;

  @override
  Future<List<SessionWinnerResultModel>> getSessionWinnerResults({
    required String sessionId,
  }) async {
    return winnerResults;
  }
}

Widget _wrap({
  required Widget child,
  overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(_EnglishLocaleController.new),
      gameRuleNamesRepositoryProvider.overrideWith(
        (ref) async => ruleNamesRepository,
      ),
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

class _EnglishLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

late GameRuleNamesRepository ruleNamesRepository;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    ruleNamesRepository = await GameRuleNamesRepository.load();
  });

  testWidgets('GameHistoryScreen shows attended games only', (tester) async {
    final entry = _historyEntry();

    await tester.pumpWidget(
      _wrap(
        overrides: [
          attendedGameHistoryProvider.overrideWith(
            () => _StubHistoryNotifier(_historyState()),
          ),
        ],
        child: const GameHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Full house'), findsOneWidget);
    expect(find.textContaining('1 of yours'), findsOneWidget);
  });

  testWidgets('tapping history row opens detail dialog', (tester) async {
    final entry = _historyEntry();
    final repository = _FakeGamesRepository(winnerResults: const []);

    await tester.pumpWidget(
      _wrap(
        overrides: [
          attendedGameHistoryProvider.overrideWith(
            () => _StubHistoryNotifier(_historyState(entries: [entry])),
          ),
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const GameHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Full house'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Game details'), findsOneWidget);
    expect(find.text('Your cartelas'), findsOneWidget);
  });

  testWidgets('detail dialog opens cartela board in nested modal', (
    tester,
  ) async {
    final entry = _historyEntry(cartelaNumber: 42);
    final repository = _FakeGamesRepository(winnerResults: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showGameHistoryDetailDialog(
                    context: context,
                    entry: entry,
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Cartela 42'), findsOneWidget);

    await tester.tap(find.text('Cartela 42'));
    await tester.pumpAndSettle();

    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Game details'), findsOneWidget);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();

    expect(find.text('FREE'), findsNothing);
    expect(find.text('Cartela 42'), findsOneWidget);
  });

  testWidgets('winner cartela opens winning pattern in nested modal', (
    tester,
  ) async {
    final entry = _historyEntry(cartelaNumber: 7, isWinner: true);
    final repository = _FakeGamesRepository(
      winnerResults: [
        SessionWinnerResultModel(
          gameCartelaId: 'gc-1',
          cartelaId: 'cartela-1',
          cartelaNumber: 7,
          amount: '50.00',
          owner: 'ME',
          columns: const [
            ['1', '2', '3', '4', '5'],
            ['6', '7', '8', '9', '10'],
            ['11', '12', 'FREE', '14', '15'],
            ['16', '17', '18', '19', '20'],
            ['21', '22', '23', '24', '25'],
          ],
          completedPatterns: const [],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showGameHistoryDetailDialog(
                    context: context,
                    entry: entry,
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cartela 7'));
    await tester.pumpAndSettle();

    expect(find.byType(WinningPatternCartelaGrid), findsOneWidget);
    expect(find.text('Game details'), findsOneWidget);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();

    expect(find.byType(WinningPatternCartelaGrid), findsNothing);
    expect(find.text('Cartela 7'), findsOneWidget);
  });
}
