import 'package:flutter/material.dart';

import '../utils/cartela_board_layout.dart';
import '../utils/cartela_pattern_progress_overlay.dart';

/// Maps a 5×5 cartela grid index to overlay coordinates.
@visibleForTesting
class CartelaPatternProgressGeometry {
  const CartelaPatternProgressGeometry._();

  static ({double cellWidth, double cellHeight}) cellSizeForBoard(
    Size boardSize, {
    double gap = 0,
  }) {
    if (gap == 0) {
      return (cellWidth: boardSize.width / 5, cellHeight: boardSize.height / 5);
    }

    return (
      cellWidth: (boardSize.width - (gap * 4)) / 5,
      cellHeight: (boardSize.height - (gap * 4)) / 5,
    );
  }

  static ({double width, double height}) drawableCellSize(
    Size boardSize, {
    double gap = 0,
    double cellInset = 0,
  }) {
    final cells = cellSizeForBoard(boardSize, gap: gap);
    return (
      width: cells.cellWidth - (cellInset * 2),
      height: cells.cellHeight - (cellInset * 2),
    );
  }

  static Offset cellCenter(
    int cellIndex,
    Size boardSize, {
    double gap = 0,
    double cellInset = 0,
  }) {
    final row = cellIndex ~/ 5;
    final col = cellIndex % 5;
    final cells = cellSizeForBoard(boardSize, gap: gap);
    return Offset(
      col * (cells.cellWidth + gap) + (cells.cellWidth / 2),
      row * (cells.cellHeight + gap) + (cells.cellHeight / 2),
    );
  }

  static Offset cellTopLeft(
    int row,
    int col,
    Size boardSize, {
    double gap = 0,
    double cellInset = 0,
  }) {
    final cells = cellSizeForBoard(boardSize, gap: gap);
    return Offset(
      col * (cells.cellWidth + gap) + cellInset,
      row * (cells.cellHeight + gap) + cellInset,
    );
  }

  static Offset cellBottomRight(
    int row,
    int col,
    Size boardSize, {
    double gap = 0,
    double cellInset = 0,
  }) {
    final cells = cellSizeForBoard(boardSize, gap: gap);
    return Offset(
      col * (cells.cellWidth + gap) + cells.cellWidth - cellInset,
      row * (cells.cellHeight + gap) + cells.cellHeight - cellInset,
    );
  }

  /// Bounding rect of the inscribed circle drawn in each grid cell.
  static Rect cellCircleBounds(
    int cellIndex,
    Size boardSize, {
    double gap = 0,
    double cellPadding = CartelaBoardLayout.cellPadding,
  }) {
    final center = cellCenter(cellIndex, boardSize, gap: gap);
    final cells = cellSizeForBoard(boardSize, gap: gap);
    final diameter = cells.cellWidth < cells.cellHeight
        ? cells.cellWidth
        : cells.cellHeight;
    final circleDiameter = diameter - (cellPadding * 2);
    return Rect.fromCenter(
      center: center,
      width: circleDiameter,
      height: circleDiameter,
    );
  }
}

class CartelaPatternProgressPainter extends CustomPainter {
  const CartelaPatternProgressPainter({
    required this.overlay,
    this.gap = 0,
    this.cellInset = 0,
    this.lineStrokeWidth = 2.5,
    this.squareStrokeWidth = 2.2,
    this.cornerStrokeWidth = 2.0,
  });

  final CartelaPatternProgressOverlay overlay;
  final double gap;
  final double cellInset;
  final double lineStrokeWidth;
  final double squareStrokeWidth;
  final double cornerStrokeWidth;

  static const _lineColor = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    for (final square in overlay.squares) {
      _paintSquareBorder(canvas, square, size);
    }

    for (final cellIndex in overlay.cornerHighlightCells) {
      _paintCornerHighlight(canvas, cellIndex, size);
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = lineStrokeWidth + 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, gap == 0 ? 3 : 2);

    final linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = lineStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in [...overlay.lines, ...overlay.shapePolylines]) {
      if (_shouldSkipDegenerateLine(line)) {
        continue;
      }
      _paintPolyline(canvas, line, size, shadowPaint, linePaint);
    }
  }

  bool _shouldSkipDegenerateLine(List<int> cells) {
    if (cells.length != 2) {
      return false;
    }

    final firstRow = cells[0] ~/ 5;
    final firstCol = cells[0] % 5;
    final secondRow = cells[1] ~/ 5;
    final secondCol = cells[1] % 5;

    return firstRow == secondRow || firstCol == secondCol;
  }

  void _paintPolyline(
    Canvas canvas,
    List<int> cells,
    Size boardSize,
    Paint shadowPaint,
    Paint linePaint,
  ) {
    if (cells.length < 2) {
      return;
    }

    final path = Path();
    for (var index = 0; index < cells.length; index++) {
      final point = CartelaPatternProgressGeometry.cellCenter(
        cells[index],
        boardSize,
        gap: gap,
        cellInset: cellInset,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);
  }

  /// Outlines a solid block: a 2x2 square or a 2x3/3x2 rectangle.
  void _paintSquareBorder(
    Canvas canvas,
    Set<int> square,
    Size boardSize,
  ) {
    if (square.length < 4) {
      return;
    }

    var union = CartelaPatternProgressGeometry.cellCircleBounds(
      square.first,
      boardSize,
      gap: gap,
      cellPadding: cellInset,
    );
    for (final cellIndex in square.skip(1)) {
      union = union.expandToInclude(
        CartelaPatternProgressGeometry.cellCircleBounds(
          cellIndex,
          boardSize,
          gap: gap,
          cellPadding: cellInset,
        ),
      );
    }
    const padding = 1.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        union.left - padding,
        union.top - padding,
        union.right + padding,
        union.bottom + padding,
      ),
      const Radius.circular(8),
    );

    final borderPaint = Paint()
      ..color = _lineColor
      ..strokeWidth = squareStrokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, borderPaint);
  }

  void _paintCornerHighlight(
    Canvas canvas,
    int cellIndex,
    Size boardSize,
  ) {
    final circleBounds = CartelaPatternProgressGeometry.cellCircleBounds(
      cellIndex,
      boardSize,
      gap: gap,
      cellPadding: cellInset,
    );
    final radius = circleBounds.width / 2;

    final borderPaint = Paint()
      ..color = _lineColor
      ..strokeWidth = cornerStrokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      circleBounds.center,
      radius - (cornerStrokeWidth / 2),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CartelaPatternProgressPainter oldDelegate) {
    return oldDelegate.overlay.lines != overlay.lines ||
        oldDelegate.overlay.squares != overlay.squares ||
        oldDelegate.overlay.shapePolylines != overlay.shapePolylines ||
        oldDelegate.overlay.cornerHighlightCells !=
            overlay.cornerHighlightCells ||
        oldDelegate.gap != gap ||
        oldDelegate.cellInset != cellInset ||
        oldDelegate.lineStrokeWidth != lineStrokeWidth ||
        oldDelegate.squareStrokeWidth != squareStrokeWidth ||
        oldDelegate.cornerStrokeWidth != cornerStrokeWidth;
  }
}

/// Converts sample-modal angle patterns (3-cell L corners) into polylines.
List<List<int>> orderedAnglePolylines(Iterable<Set<int>> anglePatterns) {
  return anglePatterns
      .map(_orderedAngleCells)
      .where((cells) => cells.length >= 2)
      .toList(growable: false);
}

List<int> _orderedAngleCells(Set<int> angle) {
  if (angle.length != 3) {
    return angle.toList()..sort();
  }

  final cells = angle.toList();
  for (final cornerIndex in cells) {
    final row = cornerIndex ~/ 5;
    final col = cornerIndex % 5;
    final neighbors = cells.where((index) {
      if (index == cornerIndex) {
        return false;
      }
      final neighborRow = index ~/ 5;
      final neighborCol = index % 5;
      return (neighborRow == row && (neighborCol - col).abs() == 1) ||
          (neighborCol == col && (neighborRow - row).abs() == 1);
    }).toList();

    if (neighbors.length == 2) {
      return [neighbors[0], cornerIndex, neighbors[1]];
    }
  }

  return cells..sort();
}

/// Converts sample-modal line patterns into ordered polylines.
List<List<int>> orderedLinePolylines(Iterable<Set<int>> linePatterns) {
  return linePatterns
      .map(
        (cells) => CartelaPatternProgressOverlay.classifyCompletedPattern(
          patternId: '',
          cells: cells,
        ),
      )
      .expand((overlay) => overlay.lines)
      .toList(growable: false);
}

CartelaPatternProgressOverlay overlayFromRulePreview({
  List<Set<int>> linePatterns = const [],
  List<Set<int>> squarePatterns = const [],
  List<Set<int>> anglePatterns = const [],
  List<Set<int>> shapePieces = const [],
  List<List<int>> shapePolylines = const [],
}) {
  final fromPieces = shapePieces.isEmpty
      ? const CartelaPatternProgressOverlay()
      : CartelaPatternProgressOverlay.merge(
          shapePieces.map((cells) => (patternId: '', cells: cells)),
        );

  final cornerCells = <int>{
    for (final angle in anglePatterns)
      if (angle.length == 1) angle.first,
    ...fromPieces.cornerHighlightCells,
  };

  final multiCellAngles = anglePatterns
      .where((angle) => angle.length >= 2)
      .toList(growable: false);

  return CartelaPatternProgressOverlay(
    lines: [
      ...orderedLinePolylines(linePatterns),
      ...fromPieces.lines,
    ],
    squares: [...squarePatterns, ...fromPieces.squares],
    shapePolylines: [
      ...shapePolylines,
      ...fromPieces.shapePolylines,
      ...orderedAnglePolylines(multiCellAngles),
    ],
    cornerHighlightCells: cornerCells,
  );
}
