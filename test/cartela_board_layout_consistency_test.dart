import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  CartelaPatternProgressOverlay fourAnglesOverlay() {
    const corners = {0, 4, 20, 24};
    const squareA = {2, 3, 7, 8};
    const squareB = {10, 11, 15, 16};
    return CartelaPatternProgressOverlay.fromCompletedPatterns([
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
  }

  CartelaPatternProgressPainter findPainter(WidgetTester tester) {
    final painterFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is CartelaPatternProgressPainter,
    );
    return tester.widget<CustomPaint>(painterFinder).painter
        as CartelaPatternProgressPainter;
  }

  testWidgets('winner review grid uses same painter params as live overlay', (
    tester,
  ) async {
    final overlay = fourAnglesOverlay();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 320,
            child: WinningPatternCartelaGrid(
              columns: columns,
              highlightCellIndexes: overlay.allOverlayCellIndexes,
              patternOverlay: overlay,
            ),
          ),
        ),
      ),
    );

    final painter = findPainter(tester);
    expect(painter.gap, 0);
    expect(painter.cellInset, CartelaBoardLayout.cellPadding);
    expect(painter.overlay.cornerHighlightCells.length, 4);
    expect(painter.overlay.squares.length, 2);
  });
}
