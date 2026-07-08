import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_shape_patterns.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_pattern_preview.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/rule_pattern_preview_grid.dart';

Set<int> _row(int r) => {for (var c = 0; c < 5; c++) r * 5 + c};

Set<int> _col(int c) => {for (var r = 0; r < 5; r++) r * 5 + c};

Set<int> _square2x2(int row, int col) {
  return {
    row * 5 + col,
    row * 5 + col + 1,
    (row + 1) * 5 + col,
    (row + 1) * 5 + col + 1,
  };
}

int countCompleteLines(Set<int> cells) {
  var count = 0;

  for (var row = 0; row < 5; row++) {
    if (_row(row).every(cells.contains)) {
      count++;
    }
  }

  for (var col = 0; col < 5; col++) {
    if (_col(col).every(cells.contains)) {
      count++;
    }
  }

  const mainDiag = [0, 6, 12, 18, 24];
  const antiDiag = [4, 8, 12, 16, 20];
  if (mainDiag.every(cells.contains)) {
    count++;
  }
  if (antiDiag.every(cells.contains)) {
    count++;
  }

  return count;
}

void expectSquareGroupsDisjoint(List<Set<int>> squares) {
  for (var i = 0; i < squares.length; i++) {
    expect(squares[i], hasLength(4));
    for (var j = i + 1; j < squares.length; j++) {
      expect(
        squares[i].intersection(squares[j]),
        isEmpty,
        reason: 'square $i overlaps square $j',
      );
    }
  }
}

void main() {
  test('preview covers all 35 product rule keys', () {
    const keys = [
      'FULL_HOUSE',
      'MIX_01',
      'MIX_02',
      'MIX_03',
      'MIX_04',
      'MIX_05',
      'MIX_06',
      'MIX_07',
      'MIX_08',
      'MIX_09',
      'MIX_10',
      'MIX_11',
      'MIX_12',
      'MIX_13',
      'BIG_H',
      'HALF_HOUSE_10_DIRECTIONS',
      'THREE_LINES',
      'THREE_ROWS_ONE_DIAGONAL',
      'TWO_DIAGONALS_ONE_ROW',
      'THREE_PARALLEL_LINES',
      'FOUR_LINES_WITHOUT_DIAGONAL',
      'HALF_HOUSE_4_DIRECTIONS',
      'MIX_14',
      'BIG_CROSS_ONE_DIAGONAL',
      'TWO_ROWS_ONE_SQUARE_ALT',
      'SIX_LINES',
      'THREE_COLUMNS',
      'FOUR_PARALLEL_LINES',
      'FOUR_ANGLES_TWO_SQUARES',
      'FOUR_LINES',
      'THREE_ROWS',
      'TWO_ROWS_ONE_COLUMN',
      'TWO_DIAGONALS',
      'ONE_COLUMN_ONE_ROW_ONE_SQUARE',
      'BIG_T_ONE_DIAGONAL',
    ];

    for (final key in keys) {
      final samples = GameRulePatternPreview.samplesForRule(key);
      expect(samples, isNotEmpty, reason: key);
      expect(samples.first.markedCells, isNotEmpty, reason: key);
      expect(
        GameRulePatternPreview.descriptionForRule(key),
        isNotNull,
        reason: key,
      );
    }
  });

  test('half house ten directions exposes all direction samples', () {
    final samples = GameRulePatternPreview.samplesForRule(
      'HALF_HOUSE_10_DIRECTIONS',
    );

    expect(samples, hasLength(10));
    expect(samples.first.label, 'Direction 1');
    expect(samples.last.label, 'Direction 10');
  });

  test('half house four directions exposes four diagonal samples', () {
    final samples = GameRulePatternPreview.samplesForRule(
      'HALF_HOUSE_4_DIRECTIONS',
    );

    expect(samples, hasLength(4));
  });

  test('BIG_H exposes both H orientation samples', () {
    final samples = GameRulePatternPreview.samplesForRule('BIG_H');

    expect(samples, hasLength(2));
    expect(samples.first.label, 'B-O sides');
    expect(samples.last.label, 'Top-N-bottom');
  });

  test('MIX_07 exposes four big L plus diagonal orientation samples', () {
    final samples = GameRulePatternPreview.samplesForRule('MIX_07');

    expect(samples, hasLength(4));
    expect(samples.map((sample) => sample.label).toList(), [
      'Bottom left',
      'Bottom right',
      'Top left',
      'Top right',
    ]);

    for (final sample in samples) {
      expect(sample.markedCells, contains(GameRulePatternPreview.freeCenter));
    }
  });

  test('BIG_T_ONE_DIAGONAL exposes four big T plus diagonal samples', () {
    final samples = GameRulePatternPreview.samplesForRule(
      'BIG_T_ONE_DIAGONAL',
    );

    expect(samples, hasLength(4));
    expect(samples.first.label, 'Top (down)');
    expect(samples.last.label, 'Right (left)');
  });

  test('MIX_04 exposes four big T plus square orientation samples', () {
    final samples = GameRulePatternPreview.samplesForRule('MIX_04');

    expect(samples, hasLength(4));
    for (final sample in samples) {
      expect(sample.squarePatterns, hasLength(2));
      expectSquareGroupsDisjoint(sample.squarePatterns);
      final bigTCells = sample.markedCells
          .difference(sample.squarePatterns.expand((square) => square).toSet());
      expect(bigTCells, hasLength(9));
      for (final square in sample.squarePatterns) {
        expect(square.intersection(bigTCells), isEmpty);
      }
    }
  });

  test('simple three lines rule shows one representative sample', () {
    final samples = GameRulePatternPreview.samplesForRule('THREE_LINES');

    expect(samples, hasLength(1));
    expect(
      samples.first.markedCells,
      GameRulePatternPreview.previewCellsForRule('THREE_LINES'),
    );
  });

  test('ONE_COLUMN_ONE_ROW_ONE_SQUARE square is disjoint from column and row', () {
    final sample = GameRulePatternPreview.samplesForRule(
      'ONE_COLUMN_ONE_ROW_ONE_SQUARE',
    ).first;
    final square = _square2x2(1, 1);
    final columnB = _col(0);
    final row5 = _row(4);

    expect(sample.markedCells.containsAll(columnB), isTrue);
    expect(sample.markedCells.containsAll(row5), isTrue);
    expect(sample.squarePatterns.single, square);
    expect(square.intersection(columnB), isEmpty);
    expect(square.intersection(row5), isEmpty);
    expect(sample.linePatterns, [columnB, row5]);
  });

  test('MIX_10 sample has exactly 7 complete lines without diagonals', () {
    final sample = GameRulePatternPreview.samplesForRule('MIX_10').first;

    expect(sample.linePatterns, hasLength(7));
    expect(countCompleteLines(sample.markedCells), 7);
    const mainDiag = [0, 6, 12, 18, 24];
    expect(mainDiag.every(sample.markedCells.contains), isFalse);
  });

  test('MIX_01 sample shows 2 columns and 2 rows without diagonal', () {
    final sample = GameRulePatternPreview.samplesForRule('MIX_01').first;
    final colB = _col(0);
    final colN = _col(2);
    final row2 = _row(1);
    final row3 = _row(2);

    expect(sample.linePatterns, [colB, colN, row2, row3]);
    expect(countCompleteLines(sample.markedCells), 4);
    const mainDiag = [0, 6, 12, 18, 24];
    expect(mainDiag.every(sample.markedCells.contains), isFalse);
  });

  test('MIX_13 sample shows B and N columns with rows 2 and 3', () {
    final sample = GameRulePatternPreview.samplesForRule('MIX_13').first;
    final colB = _col(0);
    final colN = _col(2);
    final row2 = _row(1);
    final row3 = _row(2);

    expect(sample.linePatterns, [colB, colN, row2, row3]);
    expect(sample.markedCells.containsAll(colB), isTrue);
    expect(sample.markedCells.containsAll(colN), isTrue);
    expect(sample.markedCells.containsAll(row2), isTrue);
    expect(sample.markedCells.containsAll(row3), isTrue);
  });

  test('SIX_LINES sample has exactly 6 complete lines with overlays', () {
    final sample = GameRulePatternPreview.samplesForRule('SIX_LINES').first;

    expect(sample.linePatterns, hasLength(6));
    expect(
      sample.linePatterns,
      [_row(0), _row(2), _row(4), _col(1), _col(2), _col(4)],
    );
    expect(countCompleteLines(sample.markedCells), 6);
    const mainDiag = [0, 6, 12, 18, 24];
    expect(mainDiag.every(sample.markedCells.contains), isFalse);
  });

  test(
    'FOUR_LINES_WITHOUT_DIAGONAL differs from FOUR_LINES and has no diagonal',
    () {
      final withoutDiag = GameRulePatternPreview.samplesForRule(
        'FOUR_LINES_WITHOUT_DIAGONAL',
      ).first;
      final fourLines = GameRulePatternPreview.samplesForRule(
        'FOUR_LINES',
      ).first;

      expect(
        withoutDiag.markedCells,
        isNot(equals(fourLines.markedCells)),
      );
      expect(withoutDiag.linePatterns, hasLength(4));
      expect(countCompleteLines(withoutDiag.markedCells), 4);
      expect(withoutDiag.linePatterns, [_row(2), _row(4), _col(1), _col(3)]);
    },
  );

  test('FOUR_ANGLES_TWO_SQUARES shows four corner cells and disjoint squares', () {
    final sample = GameRulePatternPreview.samplesForRule(
      'FOUR_ANGLES_TWO_SQUARES',
    ).first;
    const corners = {0, 4, 20, 24};

    expect(sample.markedCells.containsAll(corners), isTrue);
    expect(sample.anglePatterns, isEmpty);
    expect(sample.squarePatterns, hasLength(2));
    expect(sample.squarePatterns[0], _square2x2(0, 2));
    expect(sample.squarePatterns[1], _square2x2(2, 0));
    expectSquareGroupsDisjoint(sample.squarePatterns);
    expect(sample.markedCells.intersection(corners), corners);
    for (final square in sample.squarePatterns) {
      expect(square.intersection(corners), isEmpty);
    }
  });

  test('static slot codes resolve to base rule previews', () {
    final sample = GameRulePatternPreview.samplesForRule(
      'FOUR_ANGLES_TWO_SQUARES-S3',
    ).first;

    expect(
      sample.markedCells,
      GameRulePatternPreview.samplesForRule('FOUR_ANGLES_TWO_SQUARES')
          .first
          .markedCells,
    );
    expect(
      GameRulePatternPreview.descriptionForRule('FOUR_ANGLES_TWO_SQUARES-S3'),
      isNotNull,
    );
  });

  test('square-containing rules use disjoint 2x2 groups', () {
    const keys = [
      'MIX_02',
      'MIX_08',
      'MIX_11',
      'TWO_ROWS_ONE_SQUARE_ALT',
      'FOUR_ANGLES_TWO_SQUARES',
      'ONE_COLUMN_ONE_ROW_ONE_SQUARE',
    ];

    for (final key in keys) {
      final squares = GameRulePatternPreview.samplesForRule(key)
          .first
          .squarePatterns;
      expect(squares, isNotEmpty, reason: key);
      expectSquareGroupsDisjoint(squares);
    }
  });

  test('MIX_04 uses big T orientations with non-overlapping squares', () {
    final samples = GameRulePatternPreview.samplesForRule('MIX_04');

    expect(samples, hasLength(4));
    for (final sample in samples) {
      final squares = sample.squarePatterns;
      expect(squares, hasLength(2));
      expectSquareGroupsDisjoint(squares);
      final tCells = sample.markedCells
          .difference(squares.expand((square) => square).toSet());
      expect(tCells, hasLength(9));
      for (final square in squares) {
        expect(square.intersection(tCells), isEmpty);
      }
    }
  });

  test('MIX_07 and BIG_T_ONE_DIAGONAL use all big shape orientations', () {
    final mix07 = GameRulePatternPreview.samplesForRule('MIX_07');
    final bigTDiag = GameRulePatternPreview.samplesForRule(
      'BIG_T_ONE_DIAGONAL',
    );

    expect(mix07, hasLength(4));
    expect(bigTDiag, hasLength(4));
    expect(
      mix07.first.markedCells.containsAll(BigShapePatterns.defaultBigL),
      isTrue,
    );
    expect(
      bigTDiag.first.markedCells.containsAll(BigShapePatterns.defaultBigT),
      isTrue,
    );
  });

  testWidgets('ONE_COLUMN_ONE_ROW_ONE_SQUARE preview grid renders', (
    tester,
  ) async {
    final sample = GameRulePatternPreview.samplesForRule(
      'ONE_COLUMN_ONE_ROW_ONE_SQUARE',
    ).first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RulePatternPreviewGrid(
            markedCells: sample.markedCells,
            linePatterns: sample.linePatterns,
            squarePatterns: sample.squarePatterns,
            anglePatterns: sample.anglePatterns,
          ),
        ),
      ),
    );

    expect(find.byType(RulePatternPreviewGrid), findsOneWidget);
    expect(sample.markedCells.length, greaterThan(9));
  });
}
