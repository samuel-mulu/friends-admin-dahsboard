import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_pattern_preview.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_marked_pattern_evaluator.dart';

final _now = DateTime.utc(2026, 8, 26);

String _cellValue(int row, int col) {
  if (row == 2 && col == 2) {
    return 'FREE';
  }
  return '${col * 15 + row + 1}';
}

GameCartelaModel _cartela() {
  List<String> column(int col) => [
    for (var row = 0; row < 5; row++) _cellValue(row, col),
  ];

  return GameCartelaModel(
    id: 'game-cartela-1',
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-1',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'cartela-1',
      number: 1,
      createdAt: _now,
      b: column(0),
      i: column(1),
      n: column(2),
      g: column(3),
      o: column(4),
    ),
  );
}

Set<String> _marks(Iterable<int> cellIndexes) {
  return {
    for (final index in cellIndexes)
      manualMarkKey(
        bingoColumnHeaders[index % 5],
        _cellValue(index ~/ 5, index % 5),
      ),
  };
}

CartelaPatternUiResult _evaluate(String ruleKey, Set<int> markedCells) {
  return CartelaMarkedPatternEvaluator.evaluate(
    cartela: _cartela(),
    manualMarkedNumbers: _marks(markedCells),
    ruleKey: ruleKey,
  );
}

Set<int> _row(int row) => {for (var col = 0; col < 5; col++) row * 5 + col};

Set<int> _col(int col) => {for (var row = 0; row < 5; row++) row * 5 + col};

void main() {
  group('ONE_LINE and TWO_LINES', () {
    test('ONE_LINE wins with one completed row', () {
      final result = _evaluate('ONE_LINE', _row(0));

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.lines, hasLength(1));
    });

    test('ONE_LINE highlights one-away cell on a nearly complete row', () {
      final nearlyCompleteRow = _row(0).where((index) => index != 4).toSet();
      final result = _evaluate('ONE_LINE', nearlyCompleteRow);

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.isOneAway, isTrue);
      expect(result.oneAwayCellIndexes, {4});
    });

    test('TWO_LINES wins with overlapping row and column', () {
      final result = _evaluate('TWO_LINES', {..._row(0), ..._col(0)});

      expect(result.hasLocalPatternComplete, isTrue);
      expect(result.completedPatternOverlay.lines, hasLength(2));
    });

    test('TWO_LINES is one away when only one line is complete', () {
      final oneLinePlusFourOfAnother = {
        ..._row(0),
        ..._col(1).where((index) => index != 21),
      };
      final result = _evaluate('TWO_LINES', oneLinePlusFourOfAnother);

      expect(result.hasLocalPatternComplete, isFalse);
      expect(result.isOneAway, isTrue);
      expect(result.oneAwayCellIndexes, {21});
    });

    test('preview samples exist for ONE_LINE and TWO_LINES', () {
      final oneLineSample = GameRulePatternPreview.samplesForRule('ONE_LINE');
      final twoLinesSample = GameRulePatternPreview.samplesForRule('TWO_LINES');

      expect(oneLineSample, isNotEmpty);
      expect(twoLinesSample, isNotEmpty);
      expect(oneLineSample.first.linePatterns, hasLength(1));
      expect(twoLinesSample.first.linePatterns, hasLength(2));
    });
  });
}
