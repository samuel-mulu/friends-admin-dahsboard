import 'big_shape_patterns.dart';

/// One player-facing sample board for a game-rule winning pattern.
class GameRulePatternSample {
  const GameRulePatternSample({
    required this.label,
    required this.markedCells,
    this.linePatterns = const [],
    this.squarePatterns = const [],
    this.anglePatterns = const [],
  });

  final String label;
  final Set<int> markedCells;
  final List<Set<int>> linePatterns;
  final List<Set<int>> squarePatterns;
  final List<Set<int>> anglePatterns;
}

/// Builds 5×5 winning-pattern previews for each product rule key.
///
/// Cell index = row * 5 + col (0-based). Center [2,2] is FREE on real cartelas.
class GameRulePatternPreview {
  GameRulePatternPreview._();

  static const freeCenter = 2 * 5 + 2;

  static List<GameRulePatternSample> samplesForRule(String ruleKey) {
    final key = _normalizeRuleKey(ruleKey);
    if (key == 'HALF_HOUSE_10_DIRECTIONS') {
      return _halfHouseTenDirectionSamples;
    }
    if (key == 'HALF_HOUSE_4_DIRECTIONS') {
      return _halfHouseFourDirectionSamples;
    }
    if (key == 'BIG_H') {
      return _bigHSamples;
    }
    if (key == 'MIX_07') {
      return _bigLOneDiagonalSamples;
    }
    if (key == 'BIG_T_ONE_DIAGONAL') {
      return _bigTOneDiagonalSamples;
    }
    if (key == 'MIX_04') {
      return _bigTTwoSquaresSamples;
    }

    final sample = _samples[key];
    if (sample != null) {
      return [sample];
    }

    return [
      GameRulePatternSample(label: 'Sample', markedCells: _fallbackLine),
    ];
  }

  static Set<int> previewCellsForRule(String ruleKey) {
    return samplesForRule(ruleKey).first.markedCells;
  }

  static String? descriptionForRule(String ruleKey) {
    return _descriptions[_normalizeRuleKey(ruleKey)];
  }

  /// Resolves slot static codes such as `FOUR_ANGLES_TWO_SQUARES-S3`.
  static String _normalizeRuleKey(String ruleKey) {
    final trimmed = ruleKey.trim().toUpperCase();
    final hyphenIndex = trimmed.lastIndexOf('-');
    if (hyphenIndex <= 0) {
      return trimmed;
    }

    final base = trimmed.substring(0, hyphenIndex);
    if (_samples.containsKey(base) ||
        base == 'HALF_HOUSE_10_DIRECTIONS' ||
        base == 'HALF_HOUSE_4_DIRECTIONS' ||
        base == 'BIG_H' ||
        base == 'MIX_07' ||
        base == 'BIG_T_ONE_DIAGONAL' ||
        base == 'MIX_04') {
      return base;
    }

    return trimmed;
  }

  static Set<int> _allCells() => {for (var i = 0; i < 25; i++) i};

  static Set<int> _row(int r) => {for (var c = 0; c < 5; c++) r * 5 + c};

  static Set<int> _col(int c) => {for (var r = 0; r < 5; r++) r * 5 + c};

  static Set<int> _diagMain() => {for (var i = 0; i < 5; i++) i * 5 + i};

  static Set<int> _diagAnti() => {for (var i = 0; i < 5; i++) i * 5 + (4 - i)};

  static Set<int> _square2x2(int row, int col) {
    return {
      row * 5 + col,
      row * 5 + col + 1,
      (row + 1) * 5 + col,
      (row + 1) * 5 + col + 1,
    };
  }

  static Set<int> _coords(List<List<int>> pairs) {
    return pairs.map((pair) => pair[0] * 5 + pair[1]).toSet();
  }

  static Set<int> _union(Iterable<Set<int>> parts) {
    return parts.expand((part) => part).toSet();
  }

  static GameRulePatternSample _sample({
    required Set<int> markedCells,
    List<Set<int>> linePatterns = const [],
    List<Set<int>> squarePatterns = const [],
    List<Set<int>> anglePatterns = const [],
  }) {
    return GameRulePatternSample(
      label: 'Sample',
      markedCells: markedCells,
      linePatterns: linePatterns,
      squarePatterns: squarePatterns,
      anglePatterns: anglePatterns,
    );
  }

  static final Set<int> _fourCorners = {0, 4, 20, 24};

  static final List<GameRulePatternSample> _bigHSamples =
      BigShapePatterns.bigHVariants
          .map(
            (variant) => GameRulePatternSample(
              label: variant.label,
              markedCells: variant.cells,
            ),
          )
          .toList(growable: false);

  static final List<GameRulePatternSample> _bigLOneDiagonalSamples =
      BigShapePatterns.bigLVariants
          .map(
            (variant) => GameRulePatternSample(
              label: variant.label,
              markedCells: _union([variant.cells, _diagMain()]),
            ),
          )
          .toList(growable: false);

  static final List<GameRulePatternSample> _bigTOneDiagonalSamples =
      BigShapePatterns.bigTVariants
          .map(
            (variant) => GameRulePatternSample(
              label: variant.label,
              markedCells: _union([variant.cells, _diagAnti()]),
            ),
          )
          .toList(growable: false);

  /// Preview-only square pairs per BIG T orientation (disjoint from the T cells).
  static const List<(int, int, int, int)> _mix04SquareAnchors = [
    (3, 0, 3, 3), // Top (down)
    (0, 0, 0, 3), // Bottom (up)
    (0, 1, 3, 3), // Left (right)
    (0, 0, 3, 1), // Right (left)
  ];

  static final List<GameRulePatternSample> _bigTTwoSquaresSamples =
      List<GameRulePatternSample>.generate(
        BigShapePatterns.bigTVariants.length,
        (i) {
          final variant = BigShapePatterns.bigTVariants[i];
          final anchors = _mix04SquareAnchors[i];
          final squareA = _square2x2(anchors.$1, anchors.$2);
          final squareB = _square2x2(anchors.$3, anchors.$4);
          return GameRulePatternSample(
            label: variant.label,
            markedCells: _union([variant.cells, squareA, squareB]),
            squarePatterns: [squareA, squareB],
          );
        },
        growable: false,
      );

  static final Set<int> _bigL = BigShapePatterns.defaultBigL;
  static final Set<int> _bigT = BigShapePatterns.defaultBigT;

  static final Set<int> _bigCross = _coords([
    [2, 0],
    [2, 1],
    [2, 2],
    [2, 3],
    [2, 4],
    [0, 2],
    [1, 2],
    [3, 2],
    [4, 2],
  ]);

  static final Set<int> _topRightTriangle = _coords([
    [0, 0],
    [0, 1],
    [0, 2],
    [0, 3],
    [0, 4],
    [1, 1],
    [1, 2],
    [1, 3],
    [1, 4],
    [2, 2],
    [2, 3],
    [2, 4],
    [3, 3],
    [3, 4],
    [4, 4],
  ]);

  static final Set<int> _topLeftTriangle = _coords([
    [0, 0],
    [0, 1],
    [0, 2],
    [0, 3],
    [0, 4],
    [1, 0],
    [1, 1],
    [1, 2],
    [1, 3],
    [2, 0],
    [2, 1],
    [2, 2],
    [3, 0],
    [3, 1],
    [4, 0],
  ]);

  static final Set<int> _bottomLeftTriangle = _coords([
    [0, 0],
    [1, 0],
    [1, 1],
    [2, 0],
    [2, 1],
    [2, 2],
    [3, 0],
    [3, 1],
    [3, 2],
    [3, 3],
    [4, 0],
    [4, 1],
    [4, 2],
    [4, 3],
    [4, 4],
  ]);

  static final Set<int> _bottomRightTriangle = _coords([
    [0, 4],
    [1, 3],
    [1, 4],
    [2, 2],
    [2, 3],
    [2, 4],
    [3, 1],
    [3, 2],
    [3, 3],
    [3, 4],
    [4, 0],
    [4, 1],
    [4, 2],
    [4, 3],
    [4, 4],
  ]);

  static final List<GameRulePatternSample> _halfHouseFourDirectionSamples = [
    GameRulePatternSample(label: 'Direction 1', markedCells: _topRightTriangle),
    GameRulePatternSample(label: 'Direction 2', markedCells: _topLeftTriangle),
    GameRulePatternSample(
      label: 'Direction 3',
      markedCells: _bottomLeftTriangle,
    ),
    GameRulePatternSample(
      label: 'Direction 4',
      markedCells: _bottomRightTriangle,
    ),
  ];

  static final List<GameRulePatternSample> _halfHouseTenDirectionSamples = [
    ..._halfHouseFourDirectionSamples,
    GameRulePatternSample(
      label: 'Direction 5',
      markedCells: _union([_row(0), _row(1), _row(2)]),
    ),
    GameRulePatternSample(
      label: 'Direction 6',
      markedCells: _union([_row(1), _row(2), _row(3)]),
    ),
    GameRulePatternSample(
      label: 'Direction 7',
      markedCells: _union([_row(2), _row(3), _row(4)]),
    ),
    GameRulePatternSample(
      label: 'Direction 8',
      markedCells: _union([_col(0), _col(1), _col(2)]),
    ),
    GameRulePatternSample(
      label: 'Direction 9',
      markedCells: _union([_col(1), _col(2), _col(3)]),
    ),
    GameRulePatternSample(
      label: 'Direction 10',
      markedCells: _union([_col(2), _col(3), _col(4)]),
    ),
  ];

  static final Set<int> _fallbackLine = _row(2);

  static final Set<int> _mix04SquareA = _square2x2(3, 0);
  static final Set<int> _mix04SquareB = _square2x2(3, 3);
  static final Set<int> _mix08Square = _square2x2(0, 0);
  static final Set<int> _mix11SquareA = _square2x2(0, 0);
  static final Set<int> _mix11SquareB = _square2x2(0, 3);
  static final Set<int> _mix11SquareC = _square2x2(2, 1);
  static final Set<int> _mix02SquareA = _square2x2(0, 0);
  static final Set<int> _mix02SquareB = _square2x2(0, 3);
  static final Set<int> _mix02SquareC = _square2x2(3, 0);
  static final Set<int> _mix02SquareD = _square2x2(3, 3);
  static final Set<int> _fourAnglesSquareA = _square2x2(0, 2);
  static final Set<int> _fourAnglesSquareB = _square2x2(2, 0);
  static final Set<int> _twoRowsSquare = _square2x2(0, 0);
  static final Set<int> _colRowSquare = _square2x2(1, 1);

  static final Set<int> _mix10Row0 = _row(0);
  static final Set<int> _mix10Row1 = _row(1);
  static final Set<int> _mix10Row2 = _row(2);
  static final Set<int> _mix10Row4 = _row(4);
  static final Set<int> _mix10Col0 = _col(0);
  static final Set<int> _mix10Col2 = _col(2);
  static final Set<int> _mix10Col4 = _col(4);

  static final Set<int> _sixLinesRow0 = _row(0);
  static final Set<int> _sixLinesRow2 = _row(2);
  static final Set<int> _sixLinesRow4 = _row(4);
  static final Set<int> _sixLinesCol1 = _col(1);
  static final Set<int> _sixLinesCol2 = _col(2);
  static final Set<int> _sixLinesCol4 = _col(4);

  static final Set<int> _twoColTwoRowColB = _col(0);
  static final Set<int> _twoColTwoRowColN = _col(2);
  static final Set<int> _twoColTwoRowRow2 = _row(1);
  static final Set<int> _twoColTwoRowRow3 = _row(2);

  static final Map<String, GameRulePatternSample> _samples = {
    'FULL_HOUSE': _sample(markedCells: _allCells()),
    'MIX_01': _sample(
      markedCells: _union([
        _twoColTwoRowColB,
        _twoColTwoRowColN,
        _twoColTwoRowRow2,
        _twoColTwoRowRow3,
      ]),
      linePatterns: [
        _twoColTwoRowColB,
        _twoColTwoRowColN,
        _twoColTwoRowRow2,
        _twoColTwoRowRow3,
      ],
    ),
    'MIX_02': _sample(
      markedCells: _union([
        _mix02SquareA,
        _mix02SquareB,
        _mix02SquareC,
        _mix02SquareD,
      ]),
      squarePatterns: [
        _mix02SquareA,
        _mix02SquareB,
        _mix02SquareC,
        _mix02SquareD,
      ],
    ),
    'MIX_03': _sample(
      markedCells: _union([_col(0), _col(1), _col(2), _diagMain()]),
    ),
    'MIX_04': _sample(
      markedCells: _union([_bigT, _mix04SquareA, _mix04SquareB]),
      squarePatterns: [_mix04SquareA, _mix04SquareB],
    ),
    'MIX_05': _sample(
      markedCells: _union([_row(0), _row(1), _col(0), _col(1), _diagMain()]),
    ),
    'MIX_06': _sample(markedCells: _union([_row(0), _row(1), _row(4)])),
    'MIX_07': _sample(markedCells: _union([_bigL, _diagMain()])),
    'MIX_08': _sample(
      markedCells: _union([_row(3), _row(4), _mix08Square]),
      linePatterns: [_row(3), _row(4)],
      squarePatterns: [_mix08Square],
    ),
    'MIX_09': _sample(
      markedCells: _union([_col(0), _row(4), _diagMain()]),
    ),
    'MIX_10': _sample(
      markedCells: _union([
        _mix10Row0,
        _mix10Row1,
        _mix10Row2,
        _mix10Row4,
        _mix10Col0,
        _mix10Col2,
        _mix10Col4,
      ]),
      linePatterns: [
        _mix10Row0,
        _mix10Row1,
        _mix10Row2,
        _mix10Row4,
        _mix10Col0,
        _mix10Col2,
        _mix10Col4,
      ],
    ),
    'MIX_11': _sample(
      markedCells: _union([_mix11SquareA, _mix11SquareB, _mix11SquareC]),
      squarePatterns: [_mix11SquareA, _mix11SquareB, _mix11SquareC],
    ),
    'MIX_12': _sample(markedCells: _union([_row(2), _col(2), _diagMain()])),
    'MIX_13': _sample(
      markedCells: _union([
        _twoColTwoRowColB,
        _twoColTwoRowColN,
        _twoColTwoRowRow2,
        _twoColTwoRowRow3,
      ]),
      linePatterns: [
        _twoColTwoRowColB,
        _twoColTwoRowColN,
        _twoColTwoRowRow2,
        _twoColTwoRowRow3,
      ],
    ),
    'HALF_HOUSE_10_DIRECTIONS': _sample(markedCells: _topRightTriangle),
    'THREE_LINES': _sample(markedCells: _union([_row(0), _row(1), _col(0)])),
    'THREE_ROWS_ONE_DIAGONAL': _sample(
      markedCells: _union([_row(0), _row(1), _row(2), _diagMain()]),
    ),
    'TWO_DIAGONALS_ONE_ROW': _sample(
      markedCells: _union([_diagMain(), _diagAnti(), _row(0)]),
    ),
    'THREE_PARALLEL_LINES': _sample(
      markedCells: _union([_row(0), _row(1), _row(2)]),
    ),
    'FOUR_LINES_WITHOUT_DIAGONAL': _sample(
      markedCells: _union([_row(2), _row(4), _col(1), _col(3)]),
      linePatterns: [_row(2), _row(4), _col(1), _col(3)],
    ),
    'HALF_HOUSE_4_DIRECTIONS': _sample(markedCells: _topRightTriangle),
    'MIX_14': _sample(markedCells: _union([_row(2), _row(0), _row(1)])),
    'BIG_CROSS_ONE_DIAGONAL': _sample(
      markedCells: _union([_bigCross, _diagMain()]),
    ),
    'TWO_ROWS_ONE_SQUARE_ALT': _sample(
      markedCells: _union([_row(3), _row(4), _twoRowsSquare]),
      linePatterns: [_row(3), _row(4)],
      squarePatterns: [_twoRowsSquare],
    ),
    'SIX_LINES': _sample(
      markedCells: _union([
        _sixLinesRow0,
        _sixLinesRow2,
        _sixLinesRow4,
        _sixLinesCol1,
        _sixLinesCol2,
        _sixLinesCol4,
      ]),
      linePatterns: [
        _sixLinesRow0,
        _sixLinesRow2,
        _sixLinesRow4,
        _sixLinesCol1,
        _sixLinesCol2,
        _sixLinesCol4,
      ],
    ),
    'THREE_COLUMNS': _sample(markedCells: _union([_col(0), _col(1), _col(2)])),
    'FOUR_PARALLEL_LINES': _sample(
      markedCells: _union([_row(0), _row(1), _row(2), _row(3)]),
    ),
    'FOUR_ANGLES_TWO_SQUARES': _sample(
      markedCells: _union([
        _fourCorners,
        _fourAnglesSquareA,
        _fourAnglesSquareB,
      ]),
      squarePatterns: [_fourAnglesSquareA, _fourAnglesSquareB],
    ),
    'FOUR_LINES': _sample(
      markedCells: _union([_row(0), _row(1), _col(0), _col(1)]),
    ),
    'THREE_ROWS': _sample(markedCells: _union([_row(0), _row(1), _row(2)])),
    'TWO_ROWS_ONE_COLUMN': _sample(
      markedCells: _union([_row(3), _row(4), _col(0)]),
    ),
    'TWO_DIAGONALS': _sample(
      markedCells: _union([_diagMain(), _diagAnti()]),
    ),
    'ONE_COLUMN_ONE_ROW_ONE_SQUARE': _sample(
      markedCells: _union([_col(0), _row(4), _colRowSquare]),
      linePatterns: [_col(0), _row(4)],
      squarePatterns: [_colRowSquare],
    ),
    'BIG_T_ONE_DIAGONAL': _sample(markedCells: _union([_bigT, _diagAnti()])),
  };

  static const Map<String, String> _descriptions = {
    'FULL_HOUSE': 'Complete all 25 cells on the cartela.',
    'MIX_01': 'Complete 2 columns, 2 rows, and 1 diagonal. Overlap allowed.',
    'MIX_02': 'Complete 4 separate 2x2 squares. Overlap not allowed.',
    'MIX_03': 'Complete 3 columns and 1 diagonal. Overlap allowed.',
    'MIX_04': 'Complete a big T and 2 squares. Overlap not allowed.',
    'MIX_05': 'Complete 5 lines (row, column, or diagonal). Overlap allowed.',
    'MIX_06':
        'Complete 3 lines that do not pass through FREE. Overlap allowed.',
    'MIX_07': 'Complete a big L and 1 diagonal. Overlap allowed.',
    'MIX_08': 'Complete 2 rows and 1 square. Overlap not allowed.',
    'MIX_09': 'Complete 1 column, 1 row, and 1 diagonal. Overlap allowed.',
    'MIX_10': 'Complete 7 lines (row, column, or diagonal). Overlap allowed.',
    'MIX_11': 'Complete 3 separate 2x2 squares. Overlap not allowed.',
    'MIX_12': 'Complete 3 lines that pass through FREE. Overlap allowed.',
    'MIX_13': 'Complete 2 columns and 2 rows. Overlap allowed.',
    'BIG_H': 'Complete the big H shape pattern. Overlap allowed.',
    'HALF_HOUSE_10_DIRECTIONS': 'Complete one of the 10 half-house patterns.',
    'THREE_LINES':
        'Complete 3 lines (row, column, or diagonal). Overlap allowed.',
    'THREE_ROWS_ONE_DIAGONAL':
        'Complete 3 rows and 1 diagonal. Overlap allowed.',
    'TWO_DIAGONALS_ONE_ROW': 'Complete 2 diagonals and 1 row. Overlap allowed.',
    'THREE_PARALLEL_LINES':
        'Complete 3 parallel lines (all rows or all columns). Overlap not allowed.',
    'FOUR_LINES_WITHOUT_DIAGONAL':
        'Complete 4 lines using rows/columns only (no diagonals). Overlap allowed.',
    'HALF_HOUSE_4_DIRECTIONS':
        'Complete one of the 4 diagonal half-house patterns.',
    'MIX_14':
        'Complete 1 line through FREE and 2 lines that avoid FREE. Overlap allowed.',
    'BIG_CROSS_ONE_DIAGONAL':
        'Complete a big cross and 1 diagonal. Overlap allowed.',
    'TWO_ROWS_ONE_SQUARE_ALT':
        'Complete 2 rows and 1 square. Overlap not allowed.',
    'SIX_LINES':
        'Complete 6 lines (row, column, or diagonal). Overlap allowed.',
    'THREE_COLUMNS': 'Complete any 3 full columns. Overlap allowed.',
    'FOUR_PARALLEL_LINES':
        'Complete 4 parallel lines (all rows or all columns). Overlap not allowed.',
    'FOUR_ANGLES_TWO_SQUARES':
        'Complete the 4 corner cells and 2 squares. Squares must not overlap each other or any corner cell.',
    'FOUR_LINES':
        'Complete 4 lines (row, column, or diagonal). Overlap allowed.',
    'THREE_ROWS': 'Complete any 3 full rows. Overlap allowed.',
    'TWO_ROWS_ONE_COLUMN': 'Complete 2 rows and 1 column. Overlap allowed.',
    'TWO_DIAGONALS': 'Complete both diagonals. Overlap allowed.',
    'ONE_COLUMN_ONE_ROW_ONE_SQUARE':
        'Complete 1 column, 1 row, and 1 square. Column and row may overlap; square must not overlap the line patterns.',
    'BIG_T_ONE_DIAGONAL': 'Complete a big T and 1 diagonal. Overlap allowed.',
  };
}
