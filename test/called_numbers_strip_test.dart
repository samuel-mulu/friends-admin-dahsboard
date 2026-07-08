import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_connection_status.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/called_numbers_strip.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/latest_call_pulse.dart';

CalledNumberModel _calledNumber(
  int order,
  int number, {
  String letter = 'B',
}) {
  return CalledNumberModel(
    id: 'called-$order',
    sessionId: 'session-1',
    letter: letter,
    number: number,
    order: order,
    createdAt: DateTime.utc(2026, 6, 12, 12, order),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows refresh button and invokes callback', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      _wrap(
        CalledNumbersStrip(
          calledNumbers: [_calledNumber(11, 42)],
          onRefreshCalledNumbers: () => refreshCount++,
        ),
      ),
    );

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Next ball'), findsNothing);
    expect(find.text('Catching up…'), findsNothing);
    expect(find.text('Online'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();

    expect(refreshCount, 1);
    expect(find.text('Drawn: 1'), findsOneWidget);
    expect(find.text('Draw #11'), findsNothing);
  });

  testWidgets('disables refresh while loading', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      _wrap(
        CalledNumbersStrip(
          calledNumbers: [_calledNumber(1, 8)],
          isRefreshing: true,
          onRefreshCalledNumbers: () => refreshCount++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);

    await tester.tap(find.byType(CircularProgressIndicator));
    await tester.pump();

    expect(refreshCount, 0);
  });

  testWidgets('shows connection status without sync or countdown labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CalledNumbersStrip(
          calledNumbers: [_calledNumber(11, 42)],
          connectionState: LiveConnectionState.reconnecting,
        ),
      ),
    );

    expect(find.text('Next ball · 12s'), findsNothing);
    expect(find.text('Catching up…'), findsNothing);
    expect(find.text('Reconnecting...'), findsOneWidget);
    expect(find.text('Drawn: 1'), findsOneWidget);
    expect(find.text('Draw #11'), findsNothing);
  });

  testWidgets('latest called ball wraps LatestCallPulse', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CalledNumbersStrip(
          calledNumbers: [_calledNumber(3, 42)],
        ),
      ),
    );

    expect(find.byType(LatestCallPulse), findsOneWidget);
    expect(find.text('B-42'), findsOneWidget);
  });

  testWidgets('expanded board latest cell wraps LatestCallPulse', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 400,
          child: CalledNumbersStrip(
            calledNumbers: [
              _calledNumber(1, 5),
              _calledNumber(2, 22),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pump();

    expect(find.byType(LatestCallPulse), findsNWidgets(2));
    expect(find.text('22'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
  });

  testWidgets('expanded board pulses latest letter and number', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 400,
          child: CalledNumbersStrip(
            calledNumbers: [
              _calledNumber(1, 12, letter: 'I'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pump();

    expect(find.byType(LatestCallPulse), findsNWidgets(2));
    expect(find.text('I'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('expanded board scales cells to full width', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 400,
          child: CalledNumbersStrip(
            calledNumbers: [_calledNumber(1, 22)],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsNothing);
    final pulseFinder = find.byType(LatestCallPulse);
    expect(pulseFinder, findsNWidgets(2));
    final firstSize = tester.getSize(pulseFinder.at(0));
    final secondSize = tester.getSize(pulseFinder.at(1));
    final numberPulseSize = firstSize.width > secondSize.width
        ? firstSize
        : secondSize;
    expect(numberPulseSize.width, greaterThan(18));
    expect(numberPulseSize.height, 20);
    expect(numberPulseSize.width, lessThan(40));
  });

  testWidgets('expanded board fits narrow width without overflow', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 280,
          child: CalledNumbersStrip(
            calledNumbers: [_calledNumber(1, 22)],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    final latestCellSize = tester.getSize(find.byType(LatestCallPulse).first);
    expect(latestCellSize.width, greaterThan(12));
    expect(latestCellSize.height, 20);
    expect(latestCellSize.width, lessThan(22));
  });

  testWidgets('blocked cartela chips keep 4-digit numbers on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CalledNumbersStrip(
          calledNumbers: [_calledNumber(1, 42)],
          blockedCartelaNumbers: const [2250, 3121, 4429],
        ),
      ),
    );

    expect(find.text('2250'), findsOneWidget);
    expect(find.text('3121'), findsOneWidget);
    expect(find.text('4429'), findsOneWidget);

    for (final number in [2250, 3121, 4429]) {
      final text = tester.widget<Text>(find.text('$number'));
      expect(text.maxLines, 1);
    }
  });

  testWidgets('winner cartela chip invokes callback when tapped', (tester) async {
    int? tappedNumber;

    await tester.pumpWidget(
      _wrap(
        CalledNumbersStrip(
          calledNumbers: [_calledNumber(1, 42)],
          winnerCartelaNumbers: const [7],
          onWinnerCartelaTapped: (number) => tappedNumber = number,
        ),
      ),
    );

    await tester.tap(find.text('7'));
    await tester.pump();

    expect(tappedNumber, 7);
  });
}
