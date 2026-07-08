import '../../data/models/completed_pattern_model.dart';
import '../../domain/big_shape_patterns.dart';

class CartelaPatternProgressOverlay {
  const CartelaPatternProgressOverlay({
    this.lines = const [],
    this.squares = const [],
    this.shapePolylines = const [],
    this.cornerHighlightCells = const {},
  });

  final List<List<int>> lines;
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

    if (_isSquare2x2(cells)) {
      return CartelaPatternProgressOverlay(squares: [cells]);
    }

    return const CartelaPatternProgressOverlay();
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

  static List<List<int>> _polylinesForPattern(String patternId, Set<int> cells) {
    final byId = BigShapePatterns.variantById(patternId);
    if (byId != null) {
      return byId.orderedPolylines
          .where((polyline) => polyline.length >= 2)
          .toList(growable: false);
    }

    final byCells = BigShapePatterns.variantForCells(cells);
    if (byCells != null) {
      return byCells.orderedPolylines
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
