import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_localized_name.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/game_compact_info_bar.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/rule_pattern_preview_grid.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/providers/locale_provider.dart';

GameModel _testGame({
  String name = 'Four Corners',
  GameRuleModel? gameRule,
  String gameType = 'FOUR_CORNERS',
  GameCategory category = GameCategory.normal,
  String? fixedPrizeAmount,
  int? maxCartelasPerPlayer,
}) {
  final now = DateTime.utc(2026, 6, 15);
  return GameModel(
    id: 'game-1',
    sessionId: 'session-1',
    staticCode: 'ABC',
    playCode: '123',
    name: name,
    gameRule: gameRule,
    gameType: gameType,
    entryFee: '5.00',
    prizePerCartela: '10.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '100.00',
    companyRevenue: '20.00',
    status: GameStatus.playing,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 12,
    calledNumbersCount: 7,
    registrationOpen: true,
    canRegister: true,
    category: category,
    fixedPrizeAmount: fixedPrizeAmount,
    maxCartelasPerPlayer: maxCartelasPerPlayer,
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(_EnglishLocaleController.new),
      gameRuleNamesRepositoryProvider.overrideWith(
        (ref) async => ruleNamesRepository,
      ),
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

  testWidgets('live layout hides entry and called chips', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(),
          layout: GameCompactInfoBarLayout.live,
        ),
      ),
    );

    expect(find.text('ENTRY'), findsNothing);
    expect(find.text('PRIZE'), findsOneWidget);
    expect(find.text('REG'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(find.text('CALLED'), findsNothing);
  });

  testWidgets('reg chip shows my count when provided', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(),
          layout: GameCompactInfoBarLayout.live,
          myRegisteredCartelasCount: 3,
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('reg chip defaults to zero instead of session total', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(),
          layout: GameCompactInfoBarLayout.registrationOpen,
          myRegisteredCartelasCount: 0,
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('registration layout still shows entry chip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(),
          layout: GameCompactInfoBarLayout.registrationOpen,
        ),
      ),
    );

    expect(find.text('ENTRY'), findsOneWidget);
    expect(find.text('5.00 ETB'), findsOneWidget);
  });

  testWidgets('bonus game shows bonus badge and free entry details', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(
            category: GameCategory.bonus,
            fixedPrizeAmount: '5000.00',
            maxCartelasPerPlayer: 5,
          ),
          layout: GameCompactInfoBarLayout.registrationOpen,
        ),
      ),
    );

    expect(find.text('Bonus Game'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Free entry'), findsOneWidget);
    expect(find.textContaining('Fixed prize:'), findsOneWidget);
    expect(find.text('Max 5 cartelas'), findsOneWidget);
  });

  testWidgets('big gotd shows paid entry with bonus-like metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(
            category: GameCategory.bigGotd,
            fixedPrizeAmount: '5000.00',
            maxCartelasPerPlayer: 5,
          ),
          layout: GameCompactInfoBarLayout.registrationOpen,
        ),
      ),
    );

    expect(find.text('Big GOTD'), findsOneWidget);
    expect(find.text('5.00 ETB'), findsOneWidget);
    expect(find.text('Free entry'), findsNothing);
    expect(find.textContaining('Entry Fee: 5.00'), findsOneWidget);
    expect(find.textContaining('Fixed prize:'), findsOneWidget);
    expect(find.text('Max 5 cartelas'), findsOneWidget);
  });

  testWidgets('registration layout rule chip opens rule detail dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(
            name: 'Three Lines',
            gameType: 'THREE_LINES',
            gameRule: GameRuleModel(
              id: 'rule-2',
              key: 'THREE_LINES',
              name: 'Three Lines',
              description: 'Complete 3 lines.',
            ),
          ),
          layout: GameCompactInfoBarLayout.registrationOpen,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('3 lines'));
    await tester.pumpAndSettle();

    expect(find.text('Game rule'), findsOneWidget);
    expect(find.text('Complete 3 lines.'), findsOneWidget);
    expect(find.byType(RulePatternPreviewGrid), findsOneWidget);
  });

  testWidgets('now playing chip opens rule detail dialog', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameCompactInfoBar(
          game: _testGame(
            name: 'Half House',
            gameType: 'HALF_HOUSE_10_DIRECTIONS',
            gameRule: GameRuleModel(
              id: 'rule-1',
              key: 'HALF_HOUSE_10_DIRECTIONS',
              name: 'Half House',
              description: 'Complete one of the 10 half-house patterns.',
            ),
          ),
          layout: GameCompactInfoBarLayout.live,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Half house in 10 directions'));
    await tester.pumpAndSettle();

    expect(find.text('Game rule'), findsOneWidget);
    expect(
      find.text('Complete one of the 10 half-house patterns.'),
      findsOneWidget,
    );
    expect(find.byType(RulePatternPreviewGrid), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    expect(find.text('Direction 1 of 10'), findsOneWidget);

    await tester.tap(find.byTooltip('Next sample'));
    await tester.pumpAndSettle();

    expect(find.text('Direction 2 of 10'), findsOneWidget);
  });
}
