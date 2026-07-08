import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_localized_name.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/collapsible_live_top_section.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/providers/locale_provider.dart';

GameModel _currentGame() {
  final now = DateTime.utc(2026, 6, 15);
  return GameModel(
    id: 'game-current',
    sessionId: 'session-current',
    staticCode: 'ABC',
    playCode: '111',
    name: 'Current Game',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '10.00',
    prizePerCartela: '20.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: GameStatus.playing,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 8,
    calledNumbersCount: 3,
    registrationOpen: false,
    canRegister: false,
  );
}

GameModel _nextGame() {
  final now = DateTime.utc(2026, 6, 15);
  return GameModel(
    id: 'game-next',
    sessionId: 'session-next',
    staticCode: 'DEF',
    playCode: '222',
    name: 'Upcoming Rule X',
    gameRule: null,
    gameType: 'MIX_01',
    entryFee: '5.00',
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
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            const Expanded(child: Center(child: Text('outside'))),
          ],
        ),
      ),
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

  testWidgets('live play starts with game info collapsed by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CollapsibleLiveTopSection(
          game: _currentGame(),
          nextGame: _nextGame(),
          variant: LiveTopSectionVariant.livePlay,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Full house'), findsNothing);
    expect(find.text('Next game'), findsNothing);
  });

  testWidgets('collapsed next game hides name and entry fee', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CollapsibleLiveTopSection(
          game: _currentGame(),
          nextGame: _nextGame(),
          variant: LiveTopSectionVariant.livePlay,
          initiallyExpanded: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Next game'), findsOneWidget);
    expect(find.text('2 columns 2 rows 1 diagonal'), findsNothing);
    expect(find.text('5.00 ETB'), findsNothing);
  });

  testWidgets('tap next game chip reveals detail panel', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CollapsibleLiveTopSection(
          game: _currentGame(),
          nextGame: _nextGame(),
          variant: LiveTopSectionVariant.livePlay,
          initiallyExpanded: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Next game'));
    await tester.pumpAndSettle();

    expect(find.text('2 columns 2 rows 1 diagonal'), findsOneWidget);
    expect(find.textContaining('5.00 ETB'), findsOneWidget);
    expect(find.textContaining('100.00 ETB'), findsNothing);
    expect(find.text('Register for next game'), findsNothing);
  });

  testWidgets('NEXT queue detail is display-only without registration action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CollapsibleLiveTopSection(
          game: _currentGame(),
          nextGame: _nextGame(),
          variant: LiveTopSectionVariant.livePlay,
          initiallyExpanded: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Next game'));
    await tester.pumpAndSettle();

    expect(find.text('Register for next game'), findsNothing);
    expect(find.byIcon(Icons.add_card_rounded), findsNothing);
  });

  testWidgets('next game is shown above game info and hides with it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CollapsibleLiveTopSection(
          game: _currentGame(),
          nextGame: _nextGame(),
          variant: LiveTopSectionVariant.livePlay,
          initiallyExpanded: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final currentGameTop = tester.getTopLeft(find.text('Full house')).dy;
    final nextGameTop = tester.getTopLeft(find.text('Next game')).dy;
    expect(nextGameTop, lessThan(currentGameTop));

    await tester.tap(find.byTooltip('Hide game info'));
    await tester.pumpAndSettle();

    expect(find.text('Full house'), findsNothing);
    expect(find.text('Next game'), findsNothing);
  });

  testWidgets('live play variant keeps collapsible game info', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CollapsibleLiveTopSection(
          game: _currentGame(),
          nextGame: _nextGame(),
          variant: LiveTopSectionVariant.livePlay,
          initiallyExpanded: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Next game'));
    await tester.pumpAndSettle();
    expect(find.text('2 columns 2 rows 1 diagonal'), findsOneWidget);

    await tester.tap(find.text('outside'));
    await tester.pumpAndSettle();

    expect(find.text('2 columns 2 rows 1 diagonal'), findsNothing);
    expect(find.text('PRIZE'), findsOneWidget);
    expect(find.text('Full house'), findsOneWidget);
  });
}
