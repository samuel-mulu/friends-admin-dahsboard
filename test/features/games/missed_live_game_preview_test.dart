import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_resolver.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/missed_live_game_preview.dart';

GameModel _session() {
  final now = DateTime.utc(2026, 7, 22);
  return GameModel(
    id: 'id-a',
    sessionId: 'session-a',
    staticCode: 'A1',
    playCode: 'PA1',
    name: 'Game A',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '0',
    companyRevenue: '0',
    status: GameStatus.playing,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 3,
    registrationOpen: false,
    canRegister: false,
  );
}

CalledNumberModel _num(String letter, int number, int order) {
  return CalledNumberModel(
    id: 'n-$number',
    sessionId: 'session-a',
    letter: letter,
    number: number,
    order: order,
    createdAt: DateTime.utc(2026, 7, 22),
  );
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required MissedPreviewPhase phase,
  required List<CalledNumberModel> numbers,
  int? activeNumber,
  int remainingCount = 72,
  String title = 'Big T + 2 Squares',
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MissedLiveGamePreview(
          session: _session(),
          title: title,
          phase: phase,
          calledNumbers: numbers,
          activeNumber: activeNumber,
          remainingCount: remainingCount,
        ),
      ),
    ),
  );
}

void main() {
  group('MissedLiveGamePreview', () {
    testWidgets('live: title + Live + ball strip + remaining', (tester) async {
      await _pumpPreview(
        tester,
        phase: MissedPreviewPhase.livePlaying,
        numbers: [
          _num('B', 7, 1),
          _num('I', 22, 2),
          _num('N', 48, 3),
        ],
        activeNumber: 48,
        remainingCount: 72,
      );

      expect(find.text('Big T + 2 Squares (missed game)'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('N-48'), findsOneWidget);
      expect(find.text('I-22'), findsOneWidget);
      expect(find.text('B-7'), findsOneWidget);
      expect(find.byKey(const ValueKey('missed-preview-active')), findsOneWidget);
      expect(find.byKey(const ValueKey('missed-preview-recent')), findsOneWidget);
      expect(find.text('Remaining 72'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('Amharic locale uses Live label from l10n', (tester) async {
      await _pumpPreview(
        tester,
        phase: MissedPreviewPhase.livePlaying,
        numbers: [_num('I', 20, 1)],
        activeNumber: 20,
        locale: const Locale('am'),
        title: 'ትልቅ ቲ + 2 ካሬ',
      );

      expect(find.text('ትልቅ ቲ + 2 ካሬ (ያለፈ ጨዋታ)'), findsOneWidget);
      expect(find.text('ቀጥታ'), findsOneWidget);
      expect(find.text('I-20'), findsOneWidget);
    });

    testWidgets('checking shows localized checking label without claim controls', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        phase: MissedPreviewPhase.checking,
        numbers: [_num('N', 48, 3)],
        activeNumber: 48,
      );

      expect(find.text('Checking bingo…'), findsOneWidget);
      expect(find.byKey(const ValueKey('missed-preview-active')), findsOneWidget);
      expect(find.text('N-48'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('winner window overlays balls with localized label', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        phase: MissedPreviewPhase.winnerWindow,
        numbers: [_num('N', 48, 3)],
        activeNumber: 48,
      );

      // Side status + ball-tray overlay both use gameWinnerWindowOpen.
      expect(find.text('Winner window open'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('missed-preview-winner-window-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('missed-preview-winner-window-label')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('missed-preview-active')), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('winner window overlay uses Amharic l10n', (tester) async {
      await _pumpPreview(
        tester,
        phase: MissedPreviewPhase.winnerWindow,
        numbers: [_num('G', 46, 1)],
        activeNumber: 46,
        locale: const Locale('am'),
        title: '1 ዲያጎናል መስመር',
      );

      expect(find.text('የአሸናፊ መስኮት ክፍት ነው'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('missed-preview-winner-window-overlay')),
        findsOneWidget,
      );
    });

    testWidgets('empty numbers renders waiting ball safely', (tester) async {
      await _pumpPreview(
        tester,
        phase: MissedPreviewPhase.livePlaying,
        numbers: const [],
        activeNumber: null,
        remainingCount: 75,
      );

      expect(find.byKey(const ValueKey('missed-live-game-preview')), findsOneWidget);
      expect(find.byKey(const ValueKey('missed-preview-waiting')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
