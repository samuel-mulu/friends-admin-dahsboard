import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_shape_patterns.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_marked_pattern_evaluator.dart';

void main() {
  group('BIG shape orientations in CartelaMarkedPatternEvaluator', () {
    late GameCartelaModel cartela;

    setUp(() {
      cartela = _gameCartela(number: 1);
    });

    test('BIG_H wins with either H orientation', () {
      for (final variant in BigShapePatterns.bigHVariants) {
        final result = CartelaMarkedPatternEvaluator.evaluate(
          cartela: cartela,
          manualMarkedNumbers: _marksForIndexes(cartela, variant.cells),
          ruleKey: 'BIG_H',
        );

        expect(
          result.hasLocalPatternComplete,
          isTrue,
          reason: variant.label,
        );
      }
    });

    test('MIX_07 accepts any BIG L orientation plus a diagonal', () {
      final topRightL = BigShapePatterns.bigLVariants[3].cells;
      final mainDiagonal = {for (var i = 0; i < 5; i++) i * 5 + i};

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(
          cartela,
          {...topRightL, ...mainDiagonal},
        ),
        ruleKey: 'MIX_07',
      );

      expect(result.hasLocalPatternComplete, isTrue);
    });

    test('MIX_04 accepts rotated BIG T with non-overlapping squares', () {
      final rightT = BigShapePatterns.bigTVariants[2].cells;
      final squareA = {3, 4, 8, 9};
      final squareB = {18, 19, 23, 24};

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(
          cartela,
          {...rightT, ...squareA, ...squareB},
        ),
        ruleKey: 'MIX_04',
      );

      expect(result.hasLocalPatternComplete, isTrue);
    });

    test('MIX_04 rejects BIG T when squares overlap the T cells', () {
      final downT = BigShapePatterns.bigTVariants[0].cells;
      final overlappingSquare = {6, 7, 11, 12};
      final squareB = {18, 19, 23, 24};

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(
          cartela,
          {...downT, ...overlappingSquare, ...squareB},
        ),
        ruleKey: 'MIX_04',
      );

      expect(result.hasLocalPatternComplete, isFalse);
    });

    test('BIG_T_ONE_DIAGONAL accepts rotated BIG T', () {
      final leftT = BigShapePatterns.bigTVariants[3].cells;
      final antiDiagonal = {for (var i = 0; i < 5; i++) i * 5 + (4 - i)};

      final result = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _marksForIndexes(
          cartela,
          {...leftT, ...antiDiagonal},
        ),
        ruleKey: 'BIG_T_ONE_DIAGONAL',
      );

      expect(result.hasLocalPatternComplete, isTrue);
    });
  });
}

GameCartelaModel _gameCartela({required int number}) {
  final now = DateTime.utc(2026, 6, 17);
  final columns = List<List<String>>.generate(
    5,
    (column) => List<String>.generate(
      5,
      (row) => '${(row * 5) + column + 1}',
    ),
    growable: false,
  );
  columns[2][2] = 'FREE';

  return GameCartelaModel(
    id: 'gc-$number',
    gameId: 'session-1',
    userId: 'user-1',
    cartelaId: 'cartela-$number',
    status: GameCartelaStatus.registered,
    isWinner: false,
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
