import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_board_layout.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_pattern_progress_overlay.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_pattern_progress_painter.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/winning_pattern_cartela_grid.dart';

void main() {
  const columns = [
    ['1', '2', '3', '4', '5'],
    ['16', '17', '18', '19', '20'],
    ['31', '32', 'FREE', '34', '35'],
    ['46', '47', '48', '49', '50'],
    ['61', '62', '63', '64', '65'],
  ];

  Future<void> pumpGrid(
    WidgetTester tester,
    WinningPatternCartelaGrid grid,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(height: 320, width: 320, child: grid)),
      ),
    );
  }

  CartelaPatternProgressPainter findPainter(WidgetTester tester) {
    final painterFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is CartelaPatternProgressPainter,
    );
    expect(painterFinder, findsOneWidget);
    return tester.widget<CustomPaint>(painterFinder).painter
        as CartelaPatternProgressPainter;
  }

  testWidgets('winning ball cell uses gold styling', (tester) async {
    await pumpGrid(
      tester,
      const WinningPatternCartelaGrid(
        columns: columns,
        highlightCellIndexes: {20, 21, 22, 23, 24},
        winningBallCellIndex: 20,
      ),
    );

    final goldTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => text.style?.color == AppBranding.casinoPurpleDeep);

    expect(goldTexts.any((text) => text.data == '5'), isTrue);
  });

  testWidgets('four angles winner grid paints square and corner overlays', (
    tester,
  ) async {
    const corners = {0, 4, 20, 24};
    const squareA = {2, 3, 7, 8};
    const squareB = {10, 11, 15, 16};
    final overlay = CartelaPatternProgressOverlay.fromCompletedPatterns([
      const CompletedPatternModel(
        type: 'FOUR_CORNERS',
        numbers: [],
        highlightCellIndexes: corners,
      ),
      const CompletedPatternModel(
        type: 'SQUARE_2X2',
        key: 'SQUARE_2X2_R1C3',
        numbers: [],
        highlightCellIndexes: squareA,
      ),
      const CompletedPatternModel(
        type: 'SQUARE_2X2',
        key: 'SQUARE_2X2_R3C1',
        numbers: [],
        highlightCellIndexes: squareB,
      ),
    ]);

    await pumpGrid(
      tester,
      WinningPatternCartelaGrid(
        columns: columns,
        highlightCellIndexes: {...corners, ...squareA, ...squareB, 99},
        patternOverlay: overlay,
      ),
    );

    expect(find.byType(WinningPatternCartelaGrid), findsOneWidget);
    final painter = findPainter(tester);
    expect(painter.overlay.squares, [squareA, squareB]);
    expect(painter.overlay.cornerHighlightCells, corners);
    expect(painter.cellInset, CartelaBoardLayout.cellPadding);
    expect(painter.gap, 0);
    expect(overlay.allOverlayCellIndexes, {...corners, ...squareA, ...squareB});
  });

  testWidgets('uses circular cells with board chrome like live play', (
    tester,
  ) async {
    await pumpGrid(
      tester,
      const WinningPatternCartelaGrid(
        columns: columns,
        highlightCellIndexes: {12},
      ),
    );

    expect(find.byType(DecoratedBox), findsWidgets);
    final circles = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(WinningPatternCartelaGrid),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where(
          (box) =>
              box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).shape == BoxShape.circle,
        );

    expect(circles.length, greaterThanOrEqualTo(25));
  });
}
