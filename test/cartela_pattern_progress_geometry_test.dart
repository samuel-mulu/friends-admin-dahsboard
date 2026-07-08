import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_pattern_progress_painter.dart';

void main() {
  group('CartelaPatternProgressGeometry', () {
    test('uses board height for vertical centers on compact cartelas', () {
      const boardSize = Size(100, 150);

      final top = CartelaPatternProgressGeometry.cellCenter(0, boardSize);
      final bottom = CartelaPatternProgressGeometry.cellCenter(24, boardSize);

      expect(top, const Offset(10, 15));
      expect(bottom, const Offset(90, 135));
      expect(bottom.dy, greaterThan(boardSize.width));
    });

    test('keeps square boards symmetric', () {
      const boardSize = Size(100, 100);

      final topLeft = CartelaPatternProgressGeometry.cellCenter(0, boardSize);
      final bottomRight = CartelaPatternProgressGeometry.cellCenter(
        24,
        boardSize,
      );

      expect(topLeft, const Offset(10, 10));
      expect(bottomRight, const Offset(90, 90));
    });

    test('accounts for preview gaps on both axes', () {
      const boardSize = Size(100, 100);
      const gap = 3.0;

      final bottomRight = CartelaPatternProgressGeometry.cellCenter(
        24,
        boardSize,
        gap: gap,
      );

      expect(bottomRight, const Offset(91.2, 91.2));
    });

    test('big H vertical lines span full board height', () {
      const boardSize = Size(80, 120);
      final leftColumn = [0, 5, 10, 15, 20];
      final centers = leftColumn
          .map((index) => CartelaPatternProgressGeometry.cellCenter(
                index,
                boardSize,
              ))
          .toList();

      expect(centers.first.dy, 12);
      expect(centers.last.dy, 108);
      expect(centers.last.dy - centers.first.dy, boardSize.height * 0.8);
    });

    test('cell inset shrinks drawable bounds for square overlays', () {
      const boardSize = Size(100, 100);
      const inset = 1.0;

      final topLeft = CartelaPatternProgressGeometry.cellTopLeft(
        0,
        0,
        boardSize,
        cellInset: inset,
      );
      final bottomRight = CartelaPatternProgressGeometry.cellBottomRight(
        1,
        1,
        boardSize,
        cellInset: inset,
      );

      expect(topLeft, const Offset(1, 1));
      expect(bottomRight, const Offset(39, 39));

      final drawable = CartelaPatternProgressGeometry.drawableCellSize(
        boardSize,
        cellInset: inset,
      );
      expect(drawable.width, 18);
      expect(drawable.height, 18);
    });

    test('cell circle bounds match inscribed circle diameter', () {
      const boardSize = Size(100, 100);

      final bounds = CartelaPatternProgressGeometry.cellCircleBounds(
        0,
        boardSize,
      );

      expect(bounds.width, 18);
      expect(bounds.height, 18);
      expect(bounds.center, const Offset(10, 10));
    });
  });
}
