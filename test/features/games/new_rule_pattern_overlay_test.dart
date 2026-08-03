import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/extended_game_patterns.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_marked_pattern_evaluator.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_pattern_progress_overlay.dart';

final _now = DateTime.utc(2026, 7, 31);

String _cellValue(int row, int col) {
  if (row == 2 && col == 2) {
    return 'FREE';
  }
  return '${col * 15 + row + 1}';
}

GameCartelaModel _cartela() {
  List<String> column(int col) => [
    for (var row = 0; row < 5; row++) _cellValue(row, col),
  ];

  return GameCartelaModel(
    id: 'game-cartela-1',
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-1',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'cartela-1',
      number: 1,
      createdAt: _now,
      b: column(0),
      i: column(1),
      n: column(2),
      g: column(3),
      o: column(4),
    ),
  );
}

Set<String> _marks(Iterable<int> cellIndexes) {
  return {
    for (final index in cellIndexes)
      manualMarkKey(
        bingoColumnHeaders[index % 5],
        _cellValue(index ~/ 5, index % 5),
      ),
  };
}

CartelaPatternUiResult _evaluate(String ruleKey, Set<int> markedCells) {
  return CartelaMarkedPatternEvaluator.evaluate(
    cartela: _cartela(),
    manualMarkedNumbers: _marks(markedCells),
    ruleKey: ruleKey,
  );
}

Set<int> _row(int row) => {for (var col = 0; col < 5; col++) row * 5 + col};

Set<int> _cells(List<List<int>> pairs) =>
    pairs.map((pair) => pair[0] * 5 + pair[1]).toSet();

Set<int> _rectangle(int row, int col, {required int height, required int width}) {
  return {
    for (var r = row; r < row + height; r++)
      for (var c = col; c < col + width; c++) r * 5 + c,
  };
}

Set<int> _square(int row, int col) =>
    _rectangle(row, col, height: 2, width: 2);

void main() {
  group('progress overlay for the new rule shapes', () {
    test('2x3 rectangle is outlined as a block', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'rectangle_3',
        cells: _rectangle(0, 2, height: 2, width: 3),
      );

      expect(overlay.squares, hasLength(1));
      expect(overlay.squares.single, _rectangle(0, 2, height: 2, width: 3));
      expect(overlay.isEmpty, isFalse);
    });

    test('3x2 rectangle from the API key is outlined as a block', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'rectangle_18',
        cells: _rectangle(2, 0, height: 3, width: 2),
      );

      expect(overlay.squares, hasLength(1));
    });

    test('small T is drawn as a bar stroke plus a stem stroke', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'small_t_1',
        cells: _cells([
          [0, 1],
          [0, 2],
          [0, 3],
          [1, 2],
          [2, 2],
        ]),
      );

      expect(overlay.shapePolylines, hasLength(2));
      expect(overlay.shapePolylines, contains(equals([1, 2, 3])));
      expect(overlay.shapePolylines, contains(equals([2, 7, 12])));
    });

    test('small T with a sideways bar is drawn as two strokes', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'small_t_20',
        cells: _cells([
          [0, 0],
          [1, 0],
          [2, 0],
          [1, 1],
          [1, 2],
        ]),
      );

      expect(overlay.shapePolylines, hasLength(2));
      expect(overlay.shapePolylines, contains(equals([0, 5, 10])));
      expect(overlay.shapePolylines, contains(equals([5, 6, 7])));
    });

    test('6-cell triangle is drawn as a closed outline', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'triangle_6_1',
        cells: _cells([
          [0, 0],
          [0, 1],
          [0, 2],
          [1, 0],
          [1, 1],
          [2, 0],
        ]),
      );

      expect(overlay.shapePolylines, hasLength(1));
      expect(overlay.shapePolylines.single, [0, 2, 10, 0]);
    });

    test('10-cell 4x4 triangle is drawn as a closed outline', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'triangle_4x4_1',
        cells: _cells([
          [0, 0],
          [0, 1],
          [0, 2],
          [0, 3],
          [1, 0],
          [1, 1],
          [1, 2],
          [2, 0],
          [2, 1],
          [3, 0],
        ]),
      );

      expect(overlay.shapePolylines, hasLength(1));
      expect(overlay.shapePolylines.single, [0, 3, 15, 0]);
    });

    test('single corner angle is highlighted', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'corner_2',
        cells: const {4},
      );

      expect(overlay.cornerHighlightCells, {4});
    });

    test('big N resolves by pattern id', () {
      final variant = ExtendedGamePatterns.bigNOrZVariants.first;
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: variant.id,
        cells: variant.cells,
      );

      expect(overlay.shapePolylines, hasLength(3));
    });

    test('big M resolves by cells when the API only sends PATTERN_n', () {
      final variant = ExtendedGamePatterns.bigMOrWVariants.first;
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'pattern_1',
        cells: variant.cells,
      );

      expect(overlay.shapePolylines, hasLength(3));
      expect(overlay.shapePolylines, contains(equals([0, 6, 12, 8, 4])));
    });

    test('half-house block directions keep their existing empty overlay', () {
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'half_house_top',
        cells: {..._row(0), ..._row(1), ..._row(2)},
      );

      expect(overlay.isEmpty, isTrue);
    });
  });

  group('live red-line progress covers every part of the new rules', () {
    test('BIG_L_ONE_RECTANGLE outlines the L and the rectangle', () {
      final bigL = _cells([
        [0, 0],
        [1, 0],
        [2, 0],
        [3, 0],
        [4, 0],
        [4, 1],
        [4, 2],
        [4, 3],
        [4, 4],
      ]);
      final rectangle = _rectangle(0, 2, height: 2, width: 3);

      final result = _evaluate('BIG_L_ONE_RECTANGLE', {...bigL, ...rectangle});

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines, hasLength(2));
      expect(result.completedPatternOverlay.squares, hasLength(1));
      expect(result.completedPatternOverlay.squares.single, rectangle);
    });

    test('THREE_RECTANGLES outlines all three rectangles', () {
      final result = _evaluate('THREE_RECTANGLES', {
        ..._rectangle(0, 0, height: 2, width: 3),
        ..._rectangle(2, 0, height: 3, width: 2),
        ..._rectangle(2, 2, height: 3, width: 2),
      });

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.squares, hasLength(3));
    });

    test('SMALL_T_TWO_SQUARES outlines the small T and both squares', () {
      final result = _evaluate('SMALL_T_TWO_SQUARES', {
        ..._cells([
          [0, 1],
          [0, 2],
          [0, 3],
          [1, 2],
          [2, 2],
        ]),
        ..._square(3, 0),
        ..._square(3, 3),
      });

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines, hasLength(2));
      expect(result.completedPatternOverlay.squares, hasLength(2));
    });

    test('ONE_LINE_TRIANGLE_4X4 draws the line and the triangle', () {
      final result = _evaluate('ONE_LINE_TRIANGLE_4X4', {
        ..._cells([
          [0, 0],
          [0, 1],
          [0, 2],
          [0, 3],
          [1, 0],
          [1, 1],
          [1, 2],
          [2, 0],
          [2, 1],
          [3, 0],
        ]),
        ..._row(4),
      });

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.lines, hasLength(1));
      expect(result.completedPatternOverlay.shapePolylines, hasLength(1));
    });

    test('ONE_LINE_TWO_TRIANGLES draws the line and both triangles', () {
      final result = _evaluate('ONE_LINE_TWO_TRIANGLES', {
        ..._cells([
          [0, 0],
          [0, 1],
          [0, 2],
          [1, 0],
          [1, 1],
          [2, 0],
        ]),
        ..._cells([
          [0, 4],
          [1, 3],
          [1, 4],
          [2, 2],
          [2, 3],
          [2, 4],
        ]),
        ..._row(4),
      });

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.lines, hasLength(1));
      expect(result.completedPatternOverlay.shapePolylines, hasLength(2));
    });

    test('TWO_ANGLES_THREE_LINES highlights both corner angles', () {
      final result = _evaluate('TWO_ANGLES_THREE_LINES', {
        ..._row(1),
        ..._row(2),
        ..._row(3),
        0,
        24,
      });

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.lines, hasLength(3));
      expect(result.completedPatternOverlay.cornerHighlightCells, {0, 24});
    });

    test('BIG_N_OR_Z draws the three big N strokes', () {
      final result = _evaluate(
        'BIG_N_OR_Z',
        ExtendedGamePatterns.bigNOrZVariants.first.cells,
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines, hasLength(3));
    });

    test('BIG_M_OR_W draws the three big M strokes', () {
      final result = _evaluate(
        'BIG_M_OR_W',
        ExtendedGamePatterns.bigMOrWVariants.first.cells,
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines, hasLength(3));
    });
  });

  group('ONE_ANGLE_ROW_COLUMN_DIAGONAL', () {
    test('each corner angle wins with three red strokes', () {
      for (final variant
          in ExtendedGamePatterns.oneAngleRowColumnDiagonalVariants) {
        final result = _evaluate('ONE_ANGLE_ROW_COLUMN_DIAGONAL', variant.cells);

        expect(result.hasLocalPatternComplete, isTrue, reason: variant.label);
        expect(
          result.completedPatternOverlay.shapePolylines,
          hasLength(3),
          reason: variant.label,
        );
      }
    });

    test('overlay resolves by cells when API sends PATTERN_n', () {
      final variant =
          ExtendedGamePatterns.oneAngleRowColumnDiagonalVariants.first;
      final overlay = CartelaPatternProgressOverlay.classifyCompletedPattern(
        patternId: 'pattern_1',
        cells: variant.cells,
      );

      expect(overlay.shapePolylines, hasLength(3));
      expect(overlay.shapePolylines, contains(equals([0, 1, 2, 3, 4])));
      expect(overlay.shapePolylines, contains(equals([0, 5, 10, 15, 20])));
      expect(overlay.shapePolylines, contains(equals([0, 6, 12, 18, 24])));
    });

    test('rejects a non-corner row+col+diag combination', () {
      final result = _evaluate('ONE_ANGLE_ROW_COLUMN_DIAGONAL', {
        ..._row(2),
        ..._cells([
          [0, 1],
          [1, 1],
          [2, 1],
          [3, 1],
          [4, 1],
        ]),
        ..._cells([
          [0, 0],
          [1, 1],
          [2, 2],
          [3, 3],
          [4, 4],
        ]),
      });

      expect(result.hasLocalPatternComplete, isFalse);
    });
  });

  group('BIG_T_TWO_LINES needs 2 lines beyond the T itself', () {
    final bigT = _cells([
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
    ]);

    test('a bare big T does not win', () {
      final result = _evaluate('BIG_T_TWO_LINES', bigT);

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.missingCellCount, greaterThan(0));
    });

    test('the T plus 2 independent lines wins', () {
      final result = _evaluate('BIG_T_TWO_LINES', {
        ...bigT,
        ..._row(2),
        ..._row(4),
      });

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines, hasLength(2));
      expect(result.completedPatternOverlay.lines, hasLength(2));
    });

    test('lines crossing the T are allowed', () {
      final result = _evaluate('BIG_T_TWO_LINES', {
        ...bigT,
        ..._row(2),
        ..._cells([
          [0, 4],
          [1, 3],
          [2, 2],
          [3, 1],
          [4, 0],
        ]),
      });

      expect(result.hasLocalPatternComplete, isTrue);
    });
  });
}
