/// A big N/Z or M/W orientation with the strokes used to draw it in red.
class ExtendedShapeVariant {
  const ExtendedShapeVariant({
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

/// Extended bingo pattern variants for the 9 new product rules.
///
/// Cell index = row * 5 + col (0-based). Mirrors
/// `FriendsBingo/src/game-rules/combo/extended-pattern-definitions.ts`.
class ExtendedGamePatterns {
  ExtendedGamePatterns._();

  static Set<int> cellsFromCoords(List<List<int>> pairs) {
    return pairs.map((pair) => pair[0] * 5 + pair[1]).toSet();
  }

  static List<int> polylineFromCoords(List<List<int>> pairs) {
    return pairs.map((pair) => pair[0] * 5 + pair[1]).toList(growable: false);
  }

  static const List<List<List<int>>> bigNOrZCoordVariants = [
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [1, 1],
      [2, 2],
      [3, 3],
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
      [1, 3],
      [2, 2],
      [3, 1],
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
    ],
  ];

  static const List<List<List<int>>> bigMOrWCoordVariants = [
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [1, 1],
      [2, 2],
      [1, 3],
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
    ],
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
      [3, 1],
      [2, 2],
      [3, 3],
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
      [1, 3],
      [2, 2],
      [3, 3],
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
      [1, 1],
      [2, 2],
      [3, 1],
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
    ],
  ];

  static const List<String> bigNOrZLabels = ['Big N', 'Big Z'];

  static const List<String> bigMOrWLabels = [
    'Big M',
    'Big W',
    'Sideways right',
    'Sideways left',
  ];

  static List<ExtendedShapeVariant> get bigNOrZVariants =>
      List<ExtendedShapeVariant>.generate(bigNOrZCoordVariants.length, (index) {
        return ExtendedShapeVariant(
          id: 'big_n_or_z_${index + 1}',
          label: bigNOrZLabels[index],
          cells: cellsFromCoords(bigNOrZCoordVariants[index]),
          orderedPolylines: _bigNOrZPolylines(index),
        );
      }, growable: false);

  static List<ExtendedShapeVariant> get bigMOrWVariants =>
      List<ExtendedShapeVariant>.generate(bigMOrWCoordVariants.length, (index) {
        return ExtendedShapeVariant(
          id: 'big_m_or_w_${index + 1}',
          label: bigMOrWLabels[index],
          cells: cellsFromCoords(bigMOrWCoordVariants[index]),
          orderedPolylines: _bigMOrWPolylines(index),
        );
      }, growable: false);

  static const List<String> oneAngleRowColumnDiagonalLabels = [
    'B1',
    'O1',
    'B5',
    'O5',
  ];

  /// Row ∪ column ∪ diagonal through each corner angle (B1, O1, B5, O5).
  static List<ExtendedShapeVariant> get oneAngleRowColumnDiagonalVariants {
    final row0 = [0, 1, 2, 3, 4];
    final row4 = [20, 21, 22, 23, 24];
    final colB = [0, 5, 10, 15, 20];
    final colO = [4, 9, 14, 19, 24];
    final mainDiag = [0, 6, 12, 18, 24];
    final antiDiag = [4, 8, 12, 16, 20];

    Set<int> union(Iterable<int> a, Iterable<int> b, Iterable<int> c) =>
        {...a, ...b, ...c};

    final specs = [
      (cells: union(row0, colB, mainDiag), lines: [row0, colB, mainDiag]),
      (cells: union(row0, colO, antiDiag), lines: [row0, colO, antiDiag]),
      (cells: union(row4, colB, antiDiag), lines: [row4, colB, antiDiag]),
      (cells: union(row4, colO, mainDiag), lines: [row4, colO, mainDiag]),
    ];

    return List<ExtendedShapeVariant>.generate(specs.length, (index) {
      final spec = specs[index];
      return ExtendedShapeVariant(
        id: 'one_angle_row_col_diag_${index + 1}',
        label: oneAngleRowColumnDiagonalLabels[index],
        cells: spec.cells,
        orderedPolylines: [
          for (final line in spec.lines) List<int>.from(line),
        ],
      );
    }, growable: false);
  }

  static List<ExtendedShapeVariant> get allShapeVariants => [
    ...bigNOrZVariants,
    ...bigMOrWVariants,
    ...oneAngleRowColumnDiagonalVariants,
  ];

  static ExtendedShapeVariant? variantById(String id) {
    for (final variant in allShapeVariants) {
      if (variant.id == id) {
        return variant;
      }
    }
    return null;
  }

  static ExtendedShapeVariant? variantForCells(Set<int> cells) {
    for (final variant in allShapeVariants) {
      if (variant.cells.length == cells.length &&
          variant.cells.containsAll(cells)) {
        return variant;
      }
    }
    return null;
  }

  /// Big N/Z drawn as the two upright strokes plus the connecting diagonal.
  static List<List<int>> _bigNOrZPolylines(int index) {
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
          [0, 0],
          [1, 1],
          [2, 2],
          [3, 3],
          [4, 4],
        ]),
        polylineFromCoords([
          [0, 4],
          [1, 4],
          [2, 4],
          [3, 4],
          [4, 4],
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
          [0, 4],
          [1, 3],
          [2, 2],
          [3, 1],
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
      _ => [polylineFromCoords(bigNOrZCoordVariants[index])],
    };
  }

  /// Big M/W drawn as the two outer strokes plus the middle V through FREE.
  static List<List<int>> _bigMOrWPolylines(int index) {
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
          [0, 0],
          [1, 1],
          [2, 2],
          [1, 3],
          [0, 4],
        ]),
        polylineFromCoords([
          [0, 4],
          [1, 4],
          [2, 4],
          [3, 4],
          [4, 4],
        ]),
      ],
      1 => [
        polylineFromCoords([
          [0, 0],
          [1, 0],
          [2, 0],
          [3, 0],
          [4, 0],
        ]),
        polylineFromCoords([
          [4, 0],
          [3, 1],
          [2, 2],
          [3, 3],
          [4, 4],
        ]),
        polylineFromCoords([
          [0, 4],
          [1, 4],
          [2, 4],
          [3, 4],
          [4, 4],
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
          [0, 4],
          [1, 3],
          [2, 2],
          [3, 3],
          [4, 4],
        ]),
        polylineFromCoords([
          [4, 0],
          [4, 1],
          [4, 2],
          [4, 3],
          [4, 4],
        ]),
      ],
      3 => [
        polylineFromCoords([
          [0, 0],
          [0, 1],
          [0, 2],
          [0, 3],
          [0, 4],
        ]),
        polylineFromCoords([
          [0, 0],
          [1, 1],
          [2, 2],
          [3, 1],
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
      _ => [polylineFromCoords(bigMOrWCoordVariants[index])],
    };
  }

  static List<Set<int>> buildRectangleVariants() {
    final variants = <Set<int>>[];
    for (var row = 0; row <= 3; row++) {
      for (var col = 0; col <= 2; col++) {
        variants.add({
          for (var r = row; r < row + 2; r++)
            for (var c = col; c < col + 3; c++) r * 5 + c,
        });
      }
    }
    for (var row = 0; row <= 2; row++) {
      for (var col = 0; col <= 3; col++) {
        variants.add({
          for (var r = row; r < row + 3; r++)
            for (var c = col; c < col + 2; c++) r * 5 + c,
        });
      }
    }
    return variants;
  }

  /// Small cross (+): center plus four orthogonal neighbors (centers in 1..3).
  static List<Set<int>> buildSmallCrossVariants() {
    final variants = <Set<int>>[];
    for (var row = 1; row <= 3; row++) {
      for (var col = 1; col <= 3; col++) {
        variants.add(
          cellsFromCoords([
            [row - 1, col],
            [row, col - 1],
            [row, col],
            [row, col + 1],
            [row + 1, col],
          ]),
        );
      }
    }
    return variants;
  }

  static List<Set<int>> buildSmallTVariants() {
    final variants = <Set<int>>[];
    for (var row = 0; row <= 2; row++) {
      for (var col = 0; col <= 2; col++) {
        variants.add(
          cellsFromCoords([
            [row, col],
            [row, col + 1],
            [row, col + 2],
            [row + 1, col + 1],
            [row + 2, col + 1],
          ]),
        );
      }
    }
    for (var row = 2; row <= 4; row++) {
      for (var col = 0; col <= 2; col++) {
        variants.add(
          cellsFromCoords([
            [row, col],
            [row, col + 1],
            [row, col + 2],
            [row - 1, col + 1],
            [row - 2, col + 1],
          ]),
        );
      }
    }
    for (var row = 0; row <= 2; row++) {
      for (var col = 0; col <= 2; col++) {
        variants.add(
          cellsFromCoords([
            [row, col],
            [row + 1, col],
            [row + 2, col],
            [row + 1, col + 1],
            [row + 1, col + 2],
          ]),
        );
      }
    }
    for (var row = 0; row <= 2; row++) {
      for (var col = 2; col <= 4; col++) {
        variants.add(
          cellsFromCoords([
            [row, col],
            [row + 1, col],
            [row + 2, col],
            [row + 1, col - 1],
            [row + 1, col - 2],
          ]),
        );
      }
    }
    return variants;
  }

  static List<Set<int>> buildTriangle6Variants() {
    const localShapes = <List<List<int>>>[
      [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 0],
        [1, 1],
        [2, 0],
      ],
      [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 1],
        [1, 2],
        [2, 2],
      ],
      [
        [0, 0],
        [1, 0],
        [1, 1],
        [2, 0],
        [2, 1],
        [2, 2],
      ],
      [
        [0, 2],
        [1, 1],
        [1, 2],
        [2, 0],
        [2, 1],
        [2, 2],
      ],
    ];
    final variants = <Set<int>>[];
    for (var row = 0; row <= 2; row++) {
      for (var col = 0; col <= 2; col++) {
        for (final shape in localShapes) {
          variants.add(
            cellsFromCoords([
              for (final cell in shape) [cell[0] + row, cell[1] + col],
            ]),
          );
        }
      }
    }
    return variants;
  }

  static List<Set<int>> buildTriangle4x4Variants() {
    const localShapes = <List<List<int>>>[
      [
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
      ],
      [
        [0, 0],
        [0, 1],
        [0, 2],
        [0, 3],
        [1, 1],
        [1, 2],
        [1, 3],
        [2, 2],
        [2, 3],
        [3, 3],
      ],
      [
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
      ],
      [
        [0, 3],
        [1, 2],
        [1, 3],
        [2, 1],
        [2, 2],
        [2, 3],
        [3, 0],
        [3, 1],
        [3, 2],
        [3, 3],
      ],
    ];
    final variants = <Set<int>>[];
    for (var row = 0; row <= 1; row++) {
      for (var col = 0; col <= 1; col++) {
        for (final shape in localShapes) {
          variants.add(
            cellsFromCoords([
              for (final cell in shape) [cell[0] + row, cell[1] + col],
            ]),
          );
        }
      }
    }
    return variants;
  }

  static List<Set<int>> get cornerVariants => const [
    {0},
    {4},
    {20},
    {24},
  ];
}
