import '../../data/models/completed_pattern_model.dart';
import '../../domain/big_shape_patterns.dart';
import '../../domain/extended_game_patterns.dart';

class CartelaPatternProgressOverlay {
  const CartelaPatternProgressOverlay({
    this.lines = const [],
    this.squares = const [],
    this.shapePolylines = const [],
    this.cornerHighlightCells = const {},
  });

  final List<List<int>> lines;

  /// Solid blocks outlined with a rounded border: 2x2 squares and 2x3/3x2
  /// rectangles.
  final List<Set<int>> squares;
  final List<List<int>> shapePolylines;
  final Set<int> cornerHighlightCells;

  bool get isEmpty =>
      lines.isEmpty &&
      squares.isEmpty &&
      shapePolylines.isEmpty &&
      cornerHighlightCells.isEmpty;

  /// All cell indexes that have a visible red pattern overlay element.
  Set<int> get allOverlayCellIndexes {
    final indexes = <int>{...cornerHighlightCells};
    for (final square in squares) {
      indexes.addAll(square);
    }
    for (final line in lines) {
      indexes.addAll(line);
    }
    for (final polyline in shapePolylines) {
      indexes.addAll(polyline);
    }
    return indexes;
  }

  static const fourCorners = {0, 4, 20, 24};

  static const _centerRow = [10, 11, 12, 13, 14];
  static const _centerColumn = [2, 7, 12, 17, 22];

  static CartelaPatternProgressOverlay fromCompletedPatterns(
    Iterable<CompletedPatternModel> patterns,
  ) {
    return merge(
      patterns.map(
        (pattern) {
          final patternId = _patternIdForApiPattern(pattern);
          return (
            patternId: patternId,
            cells: _resolvedCellsForPattern(
              patternId: patternId,
              cells: pattern.highlightCellIndexes,
            ),
          );
        },
      ),
    );
  }

  static String _patternIdForApiPattern(CompletedPatternModel pattern) {
    final raw = (pattern.key ?? pattern.type).trim();
    if (raw.isEmpty) {
      return pattern.type.trim().toLowerCase();
    }

    return raw
        .replaceAll('SQUARE_2X2', 'square')
        .replaceAll('FOUR_CORNERS', 'four_corners')
        .toLowerCase();
  }

  static Set<int> _resolvedCellsForPattern({
    required String patternId,
    required Set<int> cells,
  }) {
    if (cells.length == 4) {
      return cells;
    }

    final match = RegExp(r'square_r(\d+)c(\d+)$').firstMatch(patternId);
    if (match == null) {
      return cells;
    }

    final row = int.parse(match.group(1)!) - 1;
    final col = int.parse(match.group(2)!) - 1;
    if (row < 0 || row > 3 || col < 0 || col > 3) {
      return cells;
    }

    return {
      row * 5 + col,
      row * 5 + col + 1,
      (row + 1) * 5 + col,
      (row + 1) * 5 + col + 1,
    };
  }

  static CartelaPatternProgressOverlay merge(
    Iterable<({String patternId, Set<int> cells})> completedPatterns,
  ) {
    final lines = <List<int>>[];
    final squares = <Set<int>>[];
    final shapePolylines = <List<int>>[];
    final cornerHighlightCells = <int>{};

    for (final pattern in completedPatterns) {
      final classified = classifyCompletedPattern(
        patternId: pattern.patternId,
        cells: pattern.cells,
      );
      lines.addAll(classified.lines);
      squares.addAll(classified.squares);
      shapePolylines.addAll(classified.shapePolylines);
      cornerHighlightCells.addAll(classified.cornerHighlightCells);
    }

    return CartelaPatternProgressOverlay(
      lines: lines,
      squares: squares,
      shapePolylines: shapePolylines,
      cornerHighlightCells: cornerHighlightCells,
    );
  }

  static CartelaPatternProgressOverlay classifyCompletedPattern({
    required String patternId,
    required Set<int> cells,
  }) {
    if (patternId == 'four_corners' ||
        patternId == 'four_corners_1' ||
        cells == fourCorners) {
      return CartelaPatternProgressOverlay(cornerHighlightCells: fourCorners);
    }

    if (patternId == 'big_cross') {
      return const CartelaPatternProgressOverlay(
        lines: [_centerRow, _centerColumn],
      );
    }

    // Single-cell angle patterns (`CORNER_1`, `corner_2`, ...).
    if (cells.length == 1) {
      return CartelaPatternProgressOverlay(cornerHighlightCells: {...cells});
    }

    if (patternId.startsWith('square_') || _isSquare2x2(cells)) {
      return CartelaPatternProgressOverlay(squares: [cells]);
    }

    if (patternId.startsWith('row_') ||
        patternId.startsWith('column_') ||
        patternId.startsWith('diag_')) {
      final line = _orderedLineCells(cells);
      if (line.length >= 2 && !_isDegenerateAxisLine(line)) {
        return CartelaPatternProgressOverlay(lines: [line]);
      }
      return const CartelaPatternProgressOverlay();
    }

    if (patternId.startsWith('big_l') ||
        patternId.startsWith('big_t') ||
        patternId.startsWith('big_h')) {
      final polylines = _polylinesForPattern(patternId, cells);
      if (polylines.isNotEmpty) {
        return CartelaPatternProgressOverlay(shapePolylines: polylines);
      }
      return const CartelaPatternProgressOverlay();
    }

    final line = _orderedLineCells(cells);
    if (line.length >= 2 &&
        !_isDegenerateAxisLine(line) &&
        (_isSameRow(line) ||
            _isSameColumn(line) ||
            _isMainDiagonal(line) ||
            _isAntiDiagonal(line))) {
      return CartelaPatternProgressOverlay(lines: [line]);
    }

    final polylines = _polylinesForPattern(patternId, cells);
    if (polylines.isNotEmpty) {
      return CartelaPatternProgressOverlay(shapePolylines: polylines);
    }

    if (_isSquare2x2(cells) || _isRectangleBlock(cells)) {
      return CartelaPatternProgressOverlay(squares: [cells]);
    }

    final smallTPolylines = _smallTPolylines(cells);
    if (smallTPolylines.isNotEmpty) {
      return CartelaPatternProgressOverlay(shapePolylines: smallTPolylines);
    }

    final smallCrossPolylines = _smallCrossPolylines(cells);
    if (smallCrossPolylines.isNotEmpty) {
      return CartelaPatternProgressOverlay(shapePolylines: smallCrossPolylines);
    }

    final trianglePolylines = _rightTrianglePolylines(cells);
    if (trianglePolylines.isNotEmpty) {
      return CartelaPatternProgressOverlay(shapePolylines: trianglePolylines);
    }

    return const CartelaPatternProgressOverlay();
  }

  static ({int topRow, int bottomRow, int leftCol, int rightCol}) _bounds(
    Set<int> cells,
  ) {
    var topRow = 4;
    var bottomRow = 0;
    var leftCol = 4;
    var rightCol = 0;
    for (final cell in cells) {
      final row = cell ~/ 5;
      final col = cell % 5;
      if (row < topRow) {
        topRow = row;
      }
      if (row > bottomRow) {
        bottomRow = row;
      }
      if (col < leftCol) {
        leftCol = col;
      }
      if (col > rightCol) {
        rightCol = col;
      }
    }

    return (
      topRow: topRow,
      bottomRow: bottomRow,
      leftCol: leftCol,
      rightCol: rightCol,
    );
  }

  /// The filled 2x3 / 3x2 rectangle used by the rectangle rules. Deliberately
  /// narrow so larger filled regions (half-house rows/columns) keep their
  /// existing overlay.
  static bool _isRectangleBlock(Set<int> cells) {
    if (cells.length != 6) {
      return false;
    }

    final bounds = _bounds(cells);
    final height = bounds.bottomRow - bounds.topRow + 1;
    final width = bounds.rightCol - bounds.leftCol + 1;
    if (height * width != cells.length) {
      return false;
    }

    for (var row = bounds.topRow; row <= bounds.bottomRow; row++) {
      for (var col = bounds.leftCol; col <= bounds.rightCol; col++) {
        if (!cells.contains(row * 5 + col)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Small cross (+): horizontal and vertical arms through the center cell.
  static List<List<int>> _smallCrossPolylines(Set<int> cells) {
    if (cells.length != 5) {
      return const [];
    }

    bool has(int row, int col) {
      return row >= 0 &&
          row < 5 &&
          col >= 0 &&
          col < 5 &&
          cells.contains(row * 5 + col);
    }

    for (final center in cells) {
      final row = center ~/ 5;
      final col = center % 5;
      if (has(row - 1, col) &&
          has(row + 1, col) &&
          has(row, col - 1) &&
          has(row, col + 1)) {
        return [
          [row * 5 + col - 1, center, row * 5 + col + 1],
          [(row - 1) * 5 + col, center, (row + 1) * 5 + col],
        ];
      }
    }

    return const [];
  }

  /// Small T: a 3-cell bar plus a 2-cell stem, drawn as bar + stem strokes the
  /// same way a big T is drawn.
  static List<List<int>> _smallTPolylines(Set<int> cells) {
    if (cells.length != 5) {
      return const [];
    }

    bool has(int row, int col) {
      return row >= 0 &&
          row < 5 &&
          col >= 0 &&
          col < 5 &&
          cells.contains(row * 5 + col);
    }

    for (final junction in cells) {
      final row = junction ~/ 5;
      final col = junction % 5;

      if (has(row, col - 1) && has(row, col + 1)) {
        for (final step in const [1, -1]) {
          if (has(row + step, col) && has(row + step * 2, col)) {
            return [
              [row * 5 + col - 1, junction, row * 5 + col + 1],
              [junction, (row + step) * 5 + col, (row + step * 2) * 5 + col],
            ];
          }
        }
      }

      if (has(row - 1, col) && has(row + 1, col)) {
        for (final step in const [1, -1]) {
          if (has(row, col + step) && has(row, col + step * 2)) {
            return [
              [(row - 1) * 5 + col, junction, (row + 1) * 5 + col],
              [junction, row * 5 + col + step, row * 5 + col + step * 2],
            ];
          }
        }
      }
    }

    return const [];
  }

  /// Right triangles (6-cell in a 3x3 window, 10-cell in a 4x4 window) drawn as
  /// a closed outline: the two full legs plus the hypotenuse.
  static List<List<int>> _rightTrianglePolylines(Set<int> cells) {
    if (cells.length != 6 && cells.length != 10) {
      return const [];
    }

    final bounds = _bounds(cells);
    final size = bounds.bottomRow - bounds.topRow + 1;
    if (size != bounds.rightCol - bounds.leftCol + 1 ||
        cells.length != size * (size + 1) ~/ 2) {
      return const [];
    }

    bool rowIsFull(int row) {
      for (var col = bounds.leftCol; col <= bounds.rightCol; col++) {
        if (!cells.contains(row * 5 + col)) {
          return false;
        }
      }
      return true;
    }

    bool columnIsFull(int col) {
      for (var row = bounds.topRow; row <= bounds.bottomRow; row++) {
        if (!cells.contains(row * 5 + col)) {
          return false;
        }
      }
      return true;
    }

    final int anchorRow;
    if (rowIsFull(bounds.topRow)) {
      anchorRow = bounds.topRow;
    } else if (rowIsFull(bounds.bottomRow)) {
      anchorRow = bounds.bottomRow;
    } else {
      return const [];
    }

    final int anchorCol;
    if (columnIsFull(bounds.leftCol)) {
      anchorCol = bounds.leftCol;
    } else if (columnIsFull(bounds.rightCol)) {
      anchorCol = bounds.rightCol;
    } else {
      return const [];
    }

    final farRow = anchorRow == bounds.topRow ? bounds.bottomRow : bounds.topRow;
    final farCol = anchorCol == bounds.leftCol
        ? bounds.rightCol
        : bounds.leftCol;

    return [
      [
        anchorRow * 5 + anchorCol,
        anchorRow * 5 + farCol,
        farRow * 5 + anchorCol,
        anchorRow * 5 + anchorCol,
      ],
    ];
  }

  static bool _isDegenerateAxisLine(List<int> line) {
    if (line.length != 2) {
      return false;
    }

    final firstRow = line[0] ~/ 5;
    final firstCol = line[0] % 5;
    final secondRow = line[1] ~/ 5;
    final secondCol = line[1] % 5;

    return firstRow == secondRow || firstCol == secondCol;
  }

  static bool _isSquare2x2(Set<int> cells) {
    if (cells.length != 4) {
      return false;
    }

    final rows = cells.map((index) => index ~/ 5).toList()..sort();
    final cols = cells.map((index) => index % 5).toList()..sort();
    if (rows[0] + 1 != rows[3] || cols[0] + 1 != cols[3]) {
      return false;
    }

    return cells.containsAll({
      (rows[0] * 5) + cols[0],
      (rows[0] * 5) + cols[1],
      (rows[1] * 5) + cols[0],
      (rows[1] * 5) + cols[1],
    });
  }

  /// Resolves the drawable strokes of a fixed shape by pattern id, falling back
  /// to a cell-set match because `PATTERN_GROUP` rules only send `PATTERN_<n>`.
  static List<List<int>> _polylinesForPattern(String patternId, Set<int> cells) {
    final candidates = [
      BigShapePatterns.variantById(patternId)?.orderedPolylines,
      ExtendedGamePatterns.variantById(patternId)?.orderedPolylines,
      BigShapePatterns.variantForCells(cells)?.orderedPolylines,
      ExtendedGamePatterns.variantForCells(cells)?.orderedPolylines,
    ];

    for (final polylines in candidates) {
      if (polylines == null) {
        continue;
      }

      return polylines
          .where((polyline) => polyline.length >= 2)
          .toList(growable: false);
    }

    return const [];
  }

  static List<int> _orderedLineCells(Set<int> pattern) {
    if (pattern.length != 5) {
      final ordered = pattern.toList()..sort();
      return ordered;
    }

    for (var row = 0; row < 5; row++) {
      final rowCells = {for (var col = 0; col < 5; col++) row * 5 + col};
      if (pattern.containsAll(rowCells)) {
        return List.generate(5, (col) => row * 5 + col);
      }
    }

    for (var col = 0; col < 5; col++) {
      final colCells = {for (var row = 0; row < 5; row++) row * 5 + col};
      if (pattern.containsAll(colCells)) {
        return List.generate(5, (row) => row * 5 + col);
      }
    }

    const mainDiag = [0, 6, 12, 18, 24];
    if (pattern.containsAll(mainDiag)) {
      return mainDiag;
    }

    const antiDiag = [4, 8, 12, 16, 20];
    if (pattern.containsAll(antiDiag)) {
      return antiDiag;
    }

    return pattern.toList()..sort();
  }

  static bool _isSameRow(List<int> line) {
    final row = line.first ~/ 5;
    return line.every((cell) => cell ~/ 5 == row);
  }

  static bool _isSameColumn(List<int> line) {
    final column = line.first % 5;
    return line.every((cell) => cell % 5 == column);
  }

  static bool _isMainDiagonal(List<int> line) {
    return line.every((cell) => cell ~/ 5 == cell % 5);
  }

  static bool _isAntiDiagonal(List<int> line) {
    return line.every((cell) => (cell ~/ 5) + (cell % 5) == 4);
  }
}
