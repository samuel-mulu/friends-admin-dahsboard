/// Fixed BIG L / BIG T / BIG H shape variants on the 5×5 cartela grid.
///
/// Cell index = row * 5 + col (0-based). Columns: B=0, I=1, N=2, G=3, O=4.
/// Center FREE is index 12 at [2, 2].
///
/// Coordinates mirror
/// `friends-bingo-api/src/game-rules/combo/base-pattern-generator.ts`.
class BigShapePatternVariant {
  const BigShapePatternVariant({
    required this.id,
    required this.label,
    required this.cells,
    required this.orderedPolylines,
  });

  final String id;
  final String label;
  final Set<int> cells;
  final List<List<int>> orderedPolylines;
}

class BigShapePatterns {
  BigShapePatterns._();

  static Set<int> cellsFromCoords(List<List<int>> pairs) {
    return pairs.map((pair) => pair[0] * 5 + pair[1]).toSet();
  }

  static List<int> polylineFromCoords(List<List<int>> pairs) {
    return pairs.map((pair) => pair[0] * 5 + pair[1]).toList(growable: false);
  }

  static const List<List<List<int>>> bigLCoordVariants = [
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
    ],
    [
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [4, 3],
      [4, 2],
      [4, 1],
      [4, 0],
    ],
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
    ],
    [
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [0, 3],
      [0, 2],
      [0, 1],
      [0, 0],
    ],
  ];

  static const List<List<List<int>>> bigTCoordVariants = [
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
    ],
    [
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
      [3, 2],
      [2, 2],
      [1, 2],
      [0, 2],
    ],
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [2, 1],
      [2, 2],
      [2, 3],
      [2, 4],
    ],
    [
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [2, 3],
      [2, 2],
      [2, 1],
      [2, 0],
    ],
  ];

  static const List<List<List<int>>> bigHCoordVariants = [
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [2, 1],
      [2, 2],
      [2, 3],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
      [1, 2],
      [2, 2],
      [3, 2],
    ],
  ];

  static const List<String> bigLLabels = [
    'Bottom left',
    'Bottom right',
    'Top left',
    'Top right',
  ];

  static const List<String> bigTLabels = [
    'Top (down)',
    'Bottom (up)',
    'Left (right)',
    'Right (left)',
  ];

  static const List<String> bigHLabels = [
    'B-O sides',
    'Top-N-bottom',
  ];

  static List<BigShapePatternVariant> get bigLVariants => _variants(
    prefix: 'big_l',
    labels: bigLLabels,
    coords: bigLCoordVariants,
  );

  static List<BigShapePatternVariant> get bigTVariants => _variants(
    prefix: 'big_t',
    labels: bigTLabels,
    coords: bigTCoordVariants,
  );

  static List<BigShapePatternVariant> get bigHVariants => _variants(
    prefix: 'big_h',
    labels: bigHLabels,
    coords: bigHCoordVariants,
  );

  static List<BigShapePatternVariant> get allVariants => [
    ...bigLVariants,
    ...bigTVariants,
    ...bigHVariants,
  ];

  static BigShapePatternVariant? variantById(String id) {
    for (final variant in allVariants) {
      if (variant.id == id) {
        return variant;
      }
    }
    return null;
  }

  static BigShapePatternVariant? variantForCells(Set<int> cells) {
    for (final variant in allVariants) {
      if (variant.cells == cells) {
        return variant;
      }
    }
    return null;
  }

  /// Default preview orientation (first variant) for composite MIX rule previews.
  static Set<int> get defaultBigL => bigLVariants.first.cells;
  static Set<int> get defaultBigT => bigTVariants.first.cells;
  static Set<int> get defaultBigH => bigHVariants.first.cells;

  static List<BigShapePatternVariant> _variants({
    required String prefix,
    required List<String> labels,
    required List<List<List<int>>> coords,
  }) {
    return List<BigShapePatternVariant>.generate(coords.length, (index) {
      final coordSet = coords[index];
      return BigShapePatternVariant(
        id: '${prefix}_${index + 1}',
        label: labels[index],
        cells: cellsFromCoords(coordSet),
        orderedPolylines: _polylinesForVariant(
          prefix: prefix,
          index: index,
          coordSet: coordSet,
        ),
      );
    }, growable: false);
  }

  static List<List<int>> _polylinesForVariant({
    required String prefix,
    required int index,
    required List<List<int>> coordSet,
  }) {
    if (prefix == 'big_t') {
      return switch (index) {
        0 => [
          polylineFromCoords([
            [0, 0],
            [0, 1],
            [0, 2],
            [0, 3],
            [0, 4],
          ]),
          polylineFromCoords([
            [0, 2],
            [1, 2],
            [2, 2],
            [3, 2],
            [4, 2],
          ]),
        ],
        1 => [
          polylineFromCoords([
            [4, 0],
            [4, 1],
            [4, 2],
            [4, 3],
            [4, 4],
          ]),
          polylineFromCoords([
            [4, 2],
            [3, 2],
            [2, 2],
            [1, 2],
            [0, 2],
          ]),
        ],
        2 => [
          polylineFromCoords([
            [0, 0],
            [1, 0],
            [2, 0],
            [3, 0],
            [4, 0],
          ]),
          polylineFromCoords([
            [2, 0],
            [2, 1],
            [2, 2],
            [2, 3],
            [2, 4],
          ]),
        ],
        3 => [
          polylineFromCoords([
            [0, 4],
            [1, 4],
            [2, 4],
            [3, 4],
            [4, 4],
          ]),
          polylineFromCoords([
            [2, 4],
            [2, 3],
            [2, 2],
            [2, 1],
            [2, 0],
          ]),
        ],
        _ => [polylineFromCoords(coordSet)],
      };
    }

    if (prefix == 'big_l') {
      return switch (index) {
        0 => [
          polylineFromCoords([
            [0, 0],
            [1, 0],
            [2, 0],
            [3, 0],
            [4, 0],
          ]),
          polylineFromCoords([
            [4, 0],
            [4, 1],
            [4, 2],
            [4, 3],
            [4, 4],
          ]),
        ],
        1 => [
          polylineFromCoords([
            [0, 4],
            [1, 4],
            [2, 4],
            [3, 4],
            [4, 4],
          ]),
          polylineFromCoords([
            [4, 4],
            [4, 3],
            [4, 2],
            [4, 1],
            [4, 0],
          ]),
        ],
        2 => [
          polylineFromCoords([
            [0, 0],
            [0, 1],
            [0, 2],
            [0, 3],
            [0, 4],
          ]),
          polylineFromCoords([
            [0, 0],
            [1, 0],
            [2, 0],
            [3, 0],
            [4, 0],
          ]),
        ],
        3 => [
          polylineFromCoords([
            [0, 4],
            [0, 3],
            [0, 2],
            [0, 1],
            [0, 0],
          ]),
          polylineFromCoords([
            [0, 4],
            [1, 4],
            [2, 4],
            [3, 4],
            [4, 4],
          ]),
        ],
        _ => [polylineFromCoords(coordSet)],
      };
    }

    if (prefix == 'big_h') {
      return switch (index) {
        0 => [
          polylineFromCoords([
            [0, 0],
            [1, 0],
            [2, 0],
            [3, 0],
            [4, 0],
          ]),
          polylineFromCoords([
            [0, 4],
            [1, 4],
            [2, 4],
            [3, 4],
            [4, 4],
          ]),
          polylineFromCoords([
            [2, 0],
            [2, 1],
            [2, 2],
            [2, 3],
            [2, 4],
          ]),
        ],
        1 => [
          polylineFromCoords([
            [0, 0],
            [0, 1],
            [0, 2],
            [0, 3],
            [0, 4],
          ]),
          polylineFromCoords([
            [4, 0],
            [4, 1],
            [4, 2],
            [4, 3],
            [4, 4],
          ]),
          polylineFromCoords([
            [0, 2],
            [1, 2],
            [2, 2],
            [3, 2],
            [4, 2],
          ]),
        ],
        _ => [polylineFromCoords(coordSet)],
      };
    }

    return [polylineFromCoords(coordSet)];
  }
}
