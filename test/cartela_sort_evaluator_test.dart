import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_shape_patterns.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_marked_pattern_evaluator.dart';

void main() {
  group('CartelaMarkedPatternEvaluator', () {
    test('one-away does not depend on called numbers', () {
      final cartela = _gameCartela(number: 1);
      final missing = 24;

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForAllExcept(cartela, {missing}),
        ruleKey: 'FULL_HOUSE',
      );

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.isOneAway, isTrue);
      expect(result.oneAwayCellIndexes, {missing});
      expect(result.missingCellCount, 1);
    });

    test('completed row shows green pattern cells and line data', () {
      final cartela = _gameCartela(number: 2);
      final winningRow = _row(0);

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, winningRow),
        ruleKey: 'ONE_ROW',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.isOneAway, isFalse);
      expect(result.completedPatternCells, winningRow);
      expect(result.completedPatternLines, [
        winningRow.toList()..sort((left, right) => left.compareTo(right)),
      ]);
      expect(result.completedPatternOverlay.lines.length, 1);
    });

    test('completed square shows red square overlay during partial progress', () {
      final cartela = _gameCartela(number: 3);
      final winningSquare = _square(0, 0);

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, winningSquare),
        ruleKey: 'MIX_02',
      );

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.completedPatternOverlay.squares.length, 1);
      expect(result.completedPatternOverlay.squares.first, winningSquare);
      expect(result.completedPatternOverlay.lines, isEmpty);
    });

    test('completed square shows green cells', () {
      final cartela = _gameCartela(number: 3);
      final winningSquare = _square(2, 0);

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, winningSquare),
        ruleKey: 'ONE_COLUMN_ONE_ROW_ONE_SQUARE',
      );

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.completedPatternCells, isEmpty);
      expect(result.missingCellCount, greaterThan(0));

      final completed = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, {
          ..._column(4),
          ..._row(0),
          ...winningSquare,
        }),
        ruleKey: 'ONE_COLUMN_ONE_ROW_ONE_SQUARE',
      );

      expect(completed.hasLocalPatternComplete, isTrue);
      expect(
        completed.completedPatternCells.containsAll(winningSquare),
        isTrue,
      );
      expect(completed.completedPatternOverlay.isEmpty, isFalse);
    });

    test('completed combo shows all selected winning cells', () {
      final cartela = _gameCartela(number: 4);
      final winningCells = {
        ..._column(0),
        ..._column(1),
        ..._row(3),
        ..._row(4),
        ..._diagMain(),
      };

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, winningCells),
        ruleKey: 'MIX_01',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternCells, winningCells);
      expect(result.completedPatternLines.length, 5);
      expect(result.completedPatternOverlay.lines.length, 5);
    });

    test('MIX_02 completed squares emit square overlays', () {
      final cartela = _gameCartela(number: 20);
      final squares = {
        ..._square(0, 0),
        ..._square(0, 3),
        ..._square(3, 0),
        ..._square(3, 3),
      };

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, squares),
        ruleKey: 'MIX_02',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.squares.length, 4);
      expect(result.completedPatternOverlay.lines, isEmpty);
    });

    test('MIX_04 big T and squares emit shape and square overlays', () {
      final cartela = _gameCartela(number: 21);
      final bigT = BigShapePatterns.defaultBigT;
      const squareA = {15, 16, 20, 21};
      const squareB = {18, 19, 23, 24};

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(
          cartela,
          {...bigT, ...squareA, ...squareB},
        ),
        ruleKey: 'MIX_04',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines.length, greaterThanOrEqualTo(1));
      expect(result.completedPatternOverlay.squares.length, 2);
    });

    test('BIG_H emits shape polyline overlay', () {
      final cartela = _gameCartela(number: 22);
      final bigH = BigShapePatterns.defaultBigH;

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, bigH),
        ruleKey: 'BIG_H',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.shapePolylines.length, greaterThanOrEqualTo(1));
    });

    test(
      'FOUR_ANGLES_TWO_SQUARES matches sample layout (corners and disjoint squares)',
      () {
        final cartela = _gameCartela(number: 99);
        final winningCells = {
          0,
          4,
          20,
          24,
          ..._square(0, 2),
          ..._square(2, 0),
        };

        final result = CartelaMarkedPatternEvaluator.evaluate(
          cartela: cartela,
          manualMarkedNumbers: _marksForIndexes(cartela, winningCells),
          ruleKey: 'FOUR_ANGLES_TWO_SQUARES',
        );

        expect(result.hasLocalPatternComplete, isTrue);
        expect(
          result.completedPatternOverlay.cornerHighlightCells,
          {0, 4, 20, 24},
        );
        expect(result.completedPatternOverlay.squares.length, 2);
        expect(result.completedPatternOverlay.lines, isEmpty);
      },
    );

    test('FOUR_ANGLES_TWO_SQUARES rejects squares overlapping corners', () {
      final cartela = _gameCartela(number: 100);
      final overlappingCells = {
        0,
        4,
        20,
        24,
        ..._square(0, 0),
        ..._square(2, 2),
      };

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, overlappingCells),
        ruleKey: 'FOUR_ANGLES_TWO_SQUARES',
      );

      expect(result.hasLocalPatternComplete, isFalse);
    });

    test(
      'unmarking removes green pattern and shows one-away when applicable',
      () {
        final cartela = _gameCartela(number: 5);
        final fullRow = _row(0);
        final almostRow = Set<int>.from(fullRow)..remove(4);

        final completed = CartelaMarkedPatternEvaluator.evaluate(
          cartela: cartela,
          manualMarkedNumbers: _marksForIndexes(cartela, fullRow),
          ruleKey: 'ONE_ROW',
        );
        final oneAway = CartelaMarkedPatternEvaluator.evaluate(
          cartela: cartela,
          manualMarkedNumbers: _marksForIndexes(cartela, almostRow),
          ruleKey: 'ONE_ROW',
        );

        expect(completed.completedPatternCells, fullRow);
        expect(oneAway.completedPatternCells, isEmpty);
        expect(oneAway.isOneAway, isTrue);
        expect(oneAway.oneAwayCellIndexes, {4});
      },
    );

    test('overlapping square combinations are rejected for MIX_02', () {
      final cartela = _gameCartela(number: 6);
      final marks = _marksForIndexes(cartela, {
        ..._square(0, 0),
        ..._square(0, 1),
        ..._square(1, 0),
        ..._square(1, 1),
      });

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: marks,
        ruleKey: 'MIX_02',
      );

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.missingCellCount, greaterThan(0));
    });

    test('half house accepts a supported local half-house pattern', () {
      final cartela = _gameCartela(number: 7);

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, _topRightTriangle()),
        ruleKey: 'HALF_HOUSE_10_DIRECTIONS',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternCells, _topRightTriangle());
    });

    test('restored marks recompute pattern UI', () {
      final cartela = _gameCartela(number: 8);
      final restoredMarks = _marksForIndexes(cartela, _diagMain());

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: restoredMarks,
        ruleKey: 'ONE_DIAGONAL',
      );

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternCells, _diagMain());
    });

    test('multi-line rules track completed lines before full completion', () {
      final cartela = _gameCartela(number: 18);
      final firstLine = _row(0);
      final partialSecondLine = {5, 6, 7};

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, {
          ...firstLine,
          ...partialSecondLine,
        }),
        ruleKey: 'THREE_LINES',
      );

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.completedPatternLines, [
        firstLine.toList()..sort((left, right) => left.compareTo(right)),
      ]);
    });

    test('one-away can blink multiple equally valid target cells', () {
      final cartela = _gameCartela(number: 19);
      final firstLine = _row(0);
      final secondLine = _row(4);

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(cartela, {
          ...firstLine,
          ...secondLine,
          5,
          7,
          8,
          9,
          13,
          23,
          3,
        }),
        ruleKey: 'THREE_LINES',
      );

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.isOneAway, isTrue);
      expect(result.oneAwayCellIndexes.contains(6), isTrue);
      expect(result.oneAwayCellIndexes.contains(18), isTrue);
      expect(result.oneAwayCellIndexes.length, greaterThan(1));
    });

    test('marked sort orders higher marked count first', () {
      final first = _gameCartela(number: 30);
      final second = _gameCartela(number: 20);
      final results = {
        first.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: first,
          manualMarkedNumbers: _marksForIndexes(first, _firstNCells(9)),
          ruleKey: 'FULL_HOUSE',
        ),
        second.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: second,
          manualMarkedNumbers: _marksForIndexes(second, _firstNCells(10)),
          ruleKey: 'FULL_HOUSE',
        ),
      };

      final sorted = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [first, second],
        resultsByCartelaId: results,
        sortMode: CartelaSortMode.markedCells,
      );

      expect(sorted.first.cartela.number, 20);
    });

    test('smart sort puts completed pattern first', () {
      final completed = _gameCartela(number: 40);
      final normal = _gameCartela(number: 50);
      final results = {
        completed.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: completed,
          manualMarkedNumbers: _marksForIndexes(completed, _row(0)),
          ruleKey: 'ONE_ROW',
        ),
        normal.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: normal,
          manualMarkedNumbers: _marksForIndexes(normal, {0, 1}),
          ruleKey: 'ONE_ROW',
        ),
      };

      final sorted = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [normal, completed],
        resultsByCartelaId: results,
        sortMode: CartelaSortMode.smart,
      );

      expect(sorted.first.cartela.number, 40);
    });

    test('smart sort puts one-away cartelas above normal boards', () {
      final oneAway = _gameCartela(number: 60);
      final normal = _gameCartela(number: 70);
      final results = {
        oneAway.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: oneAway,
          manualMarkedNumbers: _marksForIndexes(oneAway, {0, 1, 2, 3}),
          ruleKey: 'ONE_ROW',
        ),
        normal.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: normal,
          manualMarkedNumbers: _marksForIndexes(normal, {0, 1}),
          ruleKey: 'ONE_ROW',
        ),
      };

      final sorted = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [normal, oneAway],
        resultsByCartelaId: results,
        sortMode: CartelaSortMode.smart,
      );

      expect(sorted.first.cartela.number, 60);
    });

    test('manual mode preserves current order', () {
      final first = _gameCartela(number: 99);
      final second = _gameCartela(number: 11);
      final results = {
        first.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: first,
          manualMarkedNumbers: _marksForAllExcept(first, {24}),
          ruleKey: 'FULL_HOUSE',
        ),
        second.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: second,
          manualMarkedNumbers: const {},
          ruleKey: 'FULL_HOUSE',
        ),
      };

      final sorted = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [first, second],
        resultsByCartelaId: results,
        sortMode: CartelaSortMode.manual,
      );

      expect(sorted.map((cartela) => cartela.cartela.number).toList(), [
        99,
        11,
      ]);
    });

    test('review smart sort orders winner before one-away before others', () {
      final winner = _gameCartela(number: 42, isWinner: true);
      final oneAway = _gameCartela(number: 7);
      final normal = _gameCartela(number: 3);

      final results = {
        winner.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: winner,
          manualMarkedNumbers: _marksForIndexes(
            winner,
            {for (var i = 0; i < 25; i++) i},
          ),
          ruleKey: 'FULL_HOUSE',
        ),
        oneAway.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: oneAway,
          manualMarkedNumbers: _marksForIndexes(
            oneAway,
            {for (var i = 0; i < 24; i++) i},
          ),
          ruleKey: 'FULL_HOUSE',
        ),
        normal.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: normal,
          manualMarkedNumbers: _marksForIndexes(normal, {0, 1, 2, 3, 4, 5}),
          ruleKey: 'FULL_HOUSE',
        ),
      };

      final sorted = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [normal, oneAway, winner],
        resultsByCartelaId: results,
        sortMode: CartelaSortMode.reviewSmart,
      );

      expect(sorted.map((cartela) => cartela.cartela.number).toList(), [
        42,
        7,
        3,
      ]);
    });

    test('called numbers changing does not reorder cartelas', () {
      final first = _gameCartela(number: 12);
      final second = _gameCartela(number: 13);
      final resultsBefore = {
        first.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: first,
          manualMarkedNumbers: _marksForIndexes(first, {0, 1, 2}),
          ruleKey: 'FULL_HOUSE',
        ),
        second.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: second,
          manualMarkedNumbers: _marksForIndexes(second, {0, 1, 2, 3}),
          ruleKey: 'FULL_HOUSE',
        ),
      };
      final resultsAfter = {
        first.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: first,
          manualMarkedNumbers: _marksForIndexes(first, {0, 1, 2}),
          ruleKey: 'FULL_HOUSE',
        ),
        second.id: CartelaMarkedPatternEvaluator.evaluate(
          cartela: second,
          manualMarkedNumbers: _marksForIndexes(second, {0, 1, 2, 3}),
          ruleKey: 'FULL_HOUSE',
        ),
      };

      final before = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [first, second],
        resultsByCartelaId: resultsBefore,
        sortMode: CartelaSortMode.smart,
      );
      final after = CartelaMarkedPatternEvaluator.sortCartelas(
        cartelas: [first, second],
        resultsByCartelaId: resultsAfter,
        sortMode: CartelaSortMode.smart,
      );

      expect(
        after.map((cartela) => cartela.cartela.number).toList(),
        before.map((cartela) => cartela.cartela.number).toList(),
      );
    });
  });
}

GameCartelaModel _gameCartela({required int number, bool isWinner = false}) {
  final now = DateTime.utc(2026, 6, 17);
  final columns = _columnsFromRows([
    ['1', '2', '3', '4', '5'],
    ['6', '7', '8', '9', '10'],
    ['11', '12', 'FREE', '14', '15'],
    ['16', '17', '18', '19', '20'],
    ['21', '22', '23', '24', '25'],
  ]);

  return GameCartelaModel(
    id: 'gc-$number',
    gameId: 'session-1',
    userId: 'user-1',
    cartelaId: 'cartela-$number',
    status: isWinner ? GameCartelaStatus.winner : GameCartelaStatus.registered,
    isWinner: isWinner,
    blockedAt: null,
    createdAt: now,
    updatedAt: now,
    cartela: CartelaModel(
      id: 'cartela-$number',
      number: number,
      createdAt: now,
      b: columns[0],
      i: columns[1],
      n: columns[2],
      g: columns[3],
      o: columns[4],
    ),
  );
}

List<List<String>> _columnsFromRows(List<List<String>> rows) {
  return List<List<String>>.generate(
    5,
    (column) => List<String>.generate(5, (row) => rows[row][column]),
    growable: false,
  );
}

Set<String> _marksForAllExcept(
  GameCartelaModel cartela,
  Set<int> excludedIndexes,
) {
  final indexes = {for (var index = 0; index < 25; index++) index}
    ..removeAll(excludedIndexes);
  return _marksForIndexes(cartela, indexes);
}

Set<String> _marksForIndexes(GameCartelaModel cartela, Set<int> indexes) {
  final marks = <String>{};
  for (final index in indexes) {
    final row = index ~/ 5;
    final column = index % 5;
    final value = cartela.cartela.columns[column][row];
    if (value == 'FREE') {
      continue;
    }
    marks.add('${bingoColumnHeaders[column]}:$value');
  }
  return marks;
}

Set<int> _firstNCells(int count) {
  final indexes = <int>{};
  for (var index = 0; index < 25 && indexes.length < count; index++) {
    if (index == 12) {
      continue;
    }
    indexes.add(index);
  }
  return indexes;
}

Set<int> _row(int row) => {
  for (var column = 0; column < 5; column++) (row * 5) + column,
};

Set<int> _column(int column) => {
  for (var row = 0; row < 5; row++) (row * 5) + column,
};

Set<int> _diagMain() => {
  for (var index = 0; index < 5; index++) (index * 5) + index,
};

Set<int> _square(int row, int column) {
  return {
    (row * 5) + column,
    (row * 5) + column + 1,
    ((row + 1) * 5) + column,
    ((row + 1) * 5) + column + 1,
  };
}

Set<int> _topRightTriangle() {
  return {0, 1, 2, 3, 4, 6, 7, 8, 9, 12, 13, 14, 18, 19, 24};
}
