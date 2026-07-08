import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_shape_patterns.dart';

void main() {
  Set<int> indexes(List<List<int>> coords) {
    return BigShapePatterns.cellsFromCoords(coords);
  }

  group('BigShapePatterns cell indices', () {
    test('BIG T variants match fixed 9-cell orientations', () {
      final variants = BigShapePatterns.bigTVariants;
      expect(variants, hasLength(4));
      expect(variants[0].cells, {0, 1, 2, 3, 4, 7, 12, 17, 22});
      expect(variants[1].cells, {2, 7, 12, 17, 20, 21, 22, 23, 24});
      expect(variants[2].cells, {0, 5, 10, 11, 12, 13, 14, 15, 20});
      expect(variants[3].cells, {4, 9, 10, 11, 12, 13, 14, 19, 24});
    });

    test('BIG L variants match fixed 9-cell orientations', () {
      final variants = BigShapePatterns.bigLVariants;
      expect(variants, hasLength(4));
      expect(variants[0].cells, {0, 5, 10, 15, 20, 21, 22, 23, 24});
      expect(variants[1].cells, {4, 9, 14, 19, 20, 21, 22, 23, 24});
      expect(variants[2].cells, {0, 1, 2, 3, 4, 5, 10, 15, 20});
      expect(variants[3].cells, {0, 1, 2, 3, 4, 9, 14, 19, 24});
    });

    test('BIG H variants match fixed 13-cell orientations', () {
      final variants = BigShapePatterns.bigHVariants;
      expect(variants, hasLength(2));
      expect(
        variants[0].cells,
        {0, 5, 10, 11, 12, 13, 14, 15, 20, 4, 9, 19, 24},
      );
      expect(
        variants[1].cells,
        {0, 1, 2, 3, 4, 7, 12, 17, 22, 20, 21, 23, 24},
      );
    });

    test('coord helper matches variant raw coordinates', () {
      for (final coords in BigShapePatterns.bigTCoordVariants) {
        expect(indexes(coords), equals(BigShapePatterns.cellsFromCoords(coords)));
      }
    });

    test('BIG L polylines are split into two connected arms', () {
      final variants = BigShapePatterns.bigLVariants;
      for (final variant in variants) {
        expect(variant.orderedPolylines, hasLength(2));
        for (final polyline in variant.orderedPolylines) {
          expect(polyline, hasLength(5));
          for (var i = 1; i < polyline.length; i++) {
            final prev = polyline[i - 1];
            final curr = polyline[i];
            final rowDelta = (curr ~/ 5) - (prev ~/ 5);
            final colDelta = (curr % 5) - (prev % 5);
            expect(
              rowDelta.abs() + colDelta.abs(),
              1,
              reason: '${variant.id} jumps between $prev and $curr',
            );
          }
        }
        expect(
          variant.orderedPolylines.expand((line) => line).toSet(),
          variant.cells,
        );
      }
    });
  });
}
