import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_shape_patterns.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_pattern_progress_overlay.dart';

void main() {
  group('CartelaPatternProgressOverlay.classifyCompletedPattern', () {
    test('four corners uses cell highlights not lines', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'four_corners',
        cells: CartelaPatternProgressOverlay.fourCorners,
      );

      expect(overlay.cornerHighlightCells, CartelaPatternProgressOverlay.fourCorners);
      expect(overlay.lines, isEmpty);
      expect(overlay.shapePolylines, isEmpty);
    });

    test('2x2 square uses square border', () {
      const square = {10, 11, 15, 16};
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'square_2_2',
        cells: square,
      );

      expect(overlay.squares, [square]);
      expect(overlay.lines, isEmpty);
    });

    test('row pattern uses ordered line', () {
      final row = {0, 1, 2, 3, 4};
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'row_0',
        cells: row,
      );

      expect(overlay.lines, [
        [0, 1, 2, 3, 4],
      ]);
    });

    test('big T uses two arm polylines', () {
      final bigT = BigShapePatterns.defaultBigT;
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'big_t_1',
        cells: bigT,
      );

      expect(overlay.shapePolylines.length, 2);
      expect(overlay.shapePolylines[0], [0, 1, 2, 3, 4]);
      expect(overlay.shapePolylines[1], [2, 7, 12, 17, 22]);
      expect(overlay.lines, isEmpty);
    });

    test('big L top-right uses two arm polylines without a diagonal connector', () {
      final topRightL = BigShapePatterns.bigLVariants[3].cells;
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'big_l_4',
        cells: topRightL,
      );

      expect(overlay.shapePolylines.length, 2);
      expect(overlay.shapePolylines[0], [4, 3, 2, 1, 0]);
      expect(overlay.shapePolylines[1], [4, 9, 14, 19, 24]);
      expect(
        overlay.shapePolylines.expand((line) => line).toSet(),
        topRightL,
      );
    });

    test('big cross uses center row and column lines', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'big_cross',
        cells: const {
          2,
          7,
          10,
          11,
          12,
          13,
          14,
          17,
          22,
        },
      );

      expect(overlay.lines.length, 2);
      expect(overlay.lines[0], [10, 11, 12, 13, 14]);
      expect(overlay.lines[1], [2, 7, 12, 17, 22]);
    });
  });

  group('CartelaPatternProgressOverlay.fromCompletedPatterns', () {
    test('does not classify two-cell column pairs as lines', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: '',
        cells: {1, 6},
      );

      expect(overlay.lines, isEmpty);
      expect(overlay.squares, isEmpty);
    });

    test('maps API FOUR_CORNERS and SQUARE_2X2 payloads', () {
      const squareA = {2, 3, 7, 8};
      const squareB = {10, 11, 15, 16};
      final overlay = CartelaPatternProgressOverlay.fromCompletedPatterns([
        const CompletedPatternModel(
          type: 'FOUR_CORNERS',
          numbers: [],
          highlightCellIndexes: CartelaPatternProgressOverlay.fourCorners,
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

      expect(overlay.cornerHighlightCells, CartelaPatternProgressOverlay.fourCorners);
      expect(overlay.squares, [squareA, squareB]);
      expect(overlay.lines, isEmpty);
      expect(
        overlay.allOverlayCellIndexes,
        {...CartelaPatternProgressOverlay.fourCorners, ...squareA, ...squareB},
      );
    });

    test('derives 2x2 cells from SQUARE_2X2 key when cells payload is empty', () {
      const square = {2, 3, 7, 8};
      final overlay = CartelaPatternProgressOverlay.fromCompletedPatterns([
        const CompletedPatternModel(
          type: 'SQUARE_2X2',
          key: 'SQUARE_2X2_R1C3',
          numbers: [],
          highlightCellIndexes: {},
        ),
      ]);

      expect(overlay.squares, [square]);
    });
  });

  group('CartelaPatternProgressOverlay.merge', () {
    test('merges multiple completed sub-patterns', () {
      const square = {10, 11, 15, 16};
      final overlay = CartelaPatternProgressOverlay.merge([
        (patternId: 'row_0', cells: {0, 1, 2, 3, 4}),
        (patternId: 'square_2_2', cells: square),
        (
          patternId: 'four_corners',
          cells: CartelaPatternProgressOverlay.fourCorners,
        ),
      ]);

      expect(overlay.lines.length, 1);
      expect(overlay.squares, [square]);
      expect(overlay.cornerHighlightCells, CartelaPatternProgressOverlay.fourCorners);
    });
  });
}
