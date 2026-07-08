import 'package:flutter/foundation.dart';

import '../../data/models/game_cartela_model.dart';
import '../../domain/big_shape_patterns.dart';
import 'cartela_mark_helpers.dart';
import 'cartela_pattern_progress_overlay.dart';

enum CartelaSortMode {
  smart,
  markedCells,
  manual,
  reviewSmart;

  static CartelaSortMode? tryParse(String? raw) {
    return switch (raw) {
      'smart' => CartelaSortMode.smart,
      'markedCells' => CartelaSortMode.markedCells,
      'manual' => CartelaSortMode.manual,
      _ => null,
    };
  }

  bool get isUserSelectable => this != CartelaSortMode.reviewSmart;

  String get storageKey => name;

  String get label {
    return switch (this) {
      CartelaSortMode.smart => 'Smart',
      CartelaSortMode.markedCells => 'Marked',
      CartelaSortMode.manual => 'Manual',
      CartelaSortMode.reviewSmart => 'Review',
    };
  }
}

@immutable
class CartelaPatternUiResult {
  const CartelaPatternUiResult({
    required this.cartelaId,
    required this.hasLocalPatternComplete,
    required this.completedPatternCells,
    required this.completedPatternOverlay,
    required this.isOneAway,
    required this.oneAwayCellIndexes,
    required this.missingCellCount,
    required this.markedCellCount,
    required this.sortScore,
  });

  final String cartelaId;
  final bool hasLocalPatternComplete;
  final Set<int> completedPatternCells;
  final CartelaPatternProgressOverlay completedPatternOverlay;

  List<List<int>> get completedPatternLines => completedPatternOverlay.lines;
  final bool isOneAway;
  final Set<int> oneAwayCellIndexes;
  final int missingCellCount;
  final int markedCellCount;
  final int sortScore;
}

class CartelaMarkedPatternEvaluator {
  CartelaMarkedPatternEvaluator._();

  static const freeCenterCellIndex = 2 * 5 + 2;

  static final Map<String, _RuleDefinition> _ruleDefinitions =
      Map<String, _RuleDefinition>.unmodifiable(_buildRuleDefinitions());

  static CartelaPatternUiResult evaluate({
    required GameCartelaModel cartela,
    required Set<String> manualMarkedNumbers,
    required String ruleKey,
  }) {
    final columns = cartela.cartela.columns;
    final markedIndexes = markedCellIndexes(
      columns: columns,
      manualMarkedNumbers: manualMarkedNumbers,
    );
    final markedCount = markedIndexes.length;

    final definition = _ruleDefinitions[ruleKey.trim().toUpperCase()];
    if (definition == null) {
      return CartelaPatternUiResult(
        cartelaId: cartela.id,
        hasLocalPatternComplete: false,
        completedPatternCells: const {},
        completedPatternOverlay: const CartelaPatternProgressOverlay(),
        isOneAway: false,
        oneAwayCellIndexes: const {},
        missingCellCount: 25,
        markedCellCount: markedCount,
        sortScore: _sortScore(
          hasLocalPatternComplete: false,
          isOneAway: false,
          missingCellCount: 25,
          markedCellCount: markedCount,
        ),
      );
    }

    final searchResult = _findBestSelections(definition, markedIndexes);
    final best = searchResult.bestSelection;
    final missingCellCount = best?.missingCellCount ?? 25;
    final hasLocalPatternComplete = missingCellCount == 0;
    final completedPatternCells = hasLocalPatternComplete && best != null
        ? best.coveredCells
        : const <int>{};
    final completedPatternOverlay =
        best?.trackedPatternOverlay ?? const CartelaPatternProgressOverlay();
    final oneAwayCellIndexes =
        !hasLocalPatternComplete &&
            best != null &&
            best.missingCells.length == 1
        ? searchResult.oneAwayCellIndexes
        : const <int>{};

    final isOneAway = oneAwayCellIndexes.isNotEmpty;

    return CartelaPatternUiResult(
      cartelaId: cartela.id,
      hasLocalPatternComplete: hasLocalPatternComplete,
      completedPatternCells: completedPatternCells,
      completedPatternOverlay: completedPatternOverlay,
      isOneAway: isOneAway,
      oneAwayCellIndexes: oneAwayCellIndexes,
      missingCellCount: missingCellCount,
      markedCellCount: markedCount,
      sortScore: _sortScore(
        hasLocalPatternComplete: hasLocalPatternComplete,
        isOneAway: isOneAway,
        missingCellCount: missingCellCount,
        markedCellCount: markedCount,
      ),
    );
  }

  static Map<String, CartelaPatternUiResult> evaluateAll({
    required Iterable<GameCartelaModel> cartelas,
    required Set<String> manualMarkedNumbers,
    required String ruleKey,
  }) {
    return {
      for (final cartela in cartelas)
        cartela.id: evaluate(
          cartela: cartela,
          manualMarkedNumbers: manualMarkedNumbers,
          ruleKey: ruleKey,
        ),
    };
  }

  static List<GameCartelaModel> sortCartelas({
    required List<GameCartelaModel> cartelas,
    required Map<String, CartelaPatternUiResult> resultsByCartelaId,
    required CartelaSortMode sortMode,
  }) {
    if (sortMode == CartelaSortMode.manual || cartelas.length <= 1) {
      return List<GameCartelaModel>.from(cartelas);
    }

    final sorted = List<GameCartelaModel>.from(cartelas)
      ..sort((left, right) {
        final leftResult = resultsByCartelaId[left.id];
        final rightResult = resultsByCartelaId[right.id];
        if (leftResult == null || rightResult == null) {
          return left.cartela.number.compareTo(right.cartela.number);
        }

        return switch (sortMode) {
          CartelaSortMode.smart => _compareSmart(
            left: left,
            right: right,
            leftResult: leftResult,
            rightResult: rightResult,
          ),
          CartelaSortMode.reviewSmart => _compareReviewSmart(
            left: left,
            right: right,
            leftResult: leftResult,
            rightResult: rightResult,
          ),
          CartelaSortMode.markedCells => _compareMarkedCells(
            left: left,
            right: right,
            leftResult: leftResult,
            rightResult: rightResult,
          ),
          CartelaSortMode.manual => 0,
        };
      });

    return sorted;
  }

  static int _compareSmart({
    required GameCartelaModel left,
    required GameCartelaModel right,
    required CartelaPatternUiResult leftResult,
    required CartelaPatternUiResult rightResult,
  }) {
    if (leftResult.hasLocalPatternComplete !=
        rightResult.hasLocalPatternComplete) {
      return rightResult.hasLocalPatternComplete ? 1 : -1;
    }

    if (leftResult.isOneAway != rightResult.isOneAway) {
      return rightResult.isOneAway ? 1 : -1;
    }

    if (leftResult.missingCellCount != rightResult.missingCellCount) {
      return leftResult.missingCellCount.compareTo(
        rightResult.missingCellCount,
      );
    }

    if (leftResult.markedCellCount != rightResult.markedCellCount) {
      return rightResult.markedCellCount.compareTo(leftResult.markedCellCount);
    }

    return left.cartela.number.compareTo(right.cartela.number);
  }

  static int _compareReviewSmart({
    required GameCartelaModel left,
    required GameCartelaModel right,
    required CartelaPatternUiResult leftResult,
    required CartelaPatternUiResult rightResult,
  }) {
    final leftWon = left.isWinner || leftResult.hasLocalPatternComplete;
    final rightWon = right.isWinner || rightResult.hasLocalPatternComplete;
    if (leftWon != rightWon) {
      return rightWon ? 1 : -1;
    }

    return _compareSmart(
      left: left,
      right: right,
      leftResult: leftResult,
      rightResult: rightResult,
    );
  }

  static int _compareMarkedCells({
    required GameCartelaModel left,
    required GameCartelaModel right,
    required CartelaPatternUiResult leftResult,
    required CartelaPatternUiResult rightResult,
  }) {
    if (leftResult.markedCellCount != rightResult.markedCellCount) {
      return rightResult.markedCellCount.compareTo(leftResult.markedCellCount);
    }

    return left.cartela.number.compareTo(right.cartela.number);
  }

  static _SelectionSearchResult _findBestSelections(
    _RuleDefinition definition,
    Set<int> markedIndexes,
  ) {
    _BestSelection? best;
    final tiedBestSelections = <_BestSelection>[];

    void evaluateSelection(List<_SelectedPattern> selection) {
      final coveredCells = <int>{};
      for (final selected in selection) {
        coveredCells.addAll(selected.pattern.cells);
      }

      final missingCells = coveredCells.difference(markedIndexes);
      final candidate = _BestSelection(
        markedIndexes: markedIndexes,
        missingCells: missingCells,
        selectedPatterns: List<_SelectedPattern>.unmodifiable(selection),
      );
      if (best == null || candidate.isBetterThan(best!)) {
        best = candidate;
        tiedBestSelections
          ..clear()
          ..add(candidate);
      } else if (best != null && candidate.isEquivalentTo(best!)) {
        tiedBestSelections.add(candidate);
      }
    }

    void chooseGroup(int groupIndex, List<_SelectedPattern> selection) {
      if (groupIndex >= definition.groups.length) {
        evaluateSelection(selection);
        return;
      }

      final group = definition.groups[groupIndex];

      void chooseCandidates(
        int startIndex,
        List<_CandidatePattern> chosenInGroup,
      ) {
        if (chosenInGroup.length == group.requiredCount) {
          final nextSelection = [
            ...selection,
            ...chosenInGroup.map(
              (pattern) =>
                  _SelectedPattern(groupKey: group.key, pattern: pattern),
            ),
          ];
          chooseGroup(groupIndex + 1, nextSelection);
          return;
        }

        for (var index = startIndex; index < group.candidates.length; index++) {
          final candidate = group.candidates[index];
          if (!_canSelectCandidate(
            candidate: candidate,
            group: group,
            chosenInGroup: chosenInGroup,
            selection: selection,
          )) {
            continue;
          }

          chosenInGroup.add(candidate);
          chooseCandidates(index + 1, chosenInGroup);
          chosenInGroup.removeLast();
        }
      }

      chooseCandidates(0, <_CandidatePattern>[]);
    }

    chooseGroup(0, <_SelectedPattern>[]);
    return _SelectionSearchResult(
      bestSelection: best,
      tiedBestSelections: List<_BestSelection>.unmodifiable(tiedBestSelections),
    );
  }

  static bool _canSelectCandidate({
    required _CandidatePattern candidate,
    required _RequiredGroup group,
    required List<_CandidatePattern> chosenInGroup,
    required List<_SelectedPattern> selection,
  }) {
    if (group.requireSameOrientation &&
        chosenInGroup.isNotEmpty &&
        chosenInGroup.first.orientation != candidate.orientation) {
      return false;
    }

    if (group.disallowOverlapWithinGroup &&
        chosenInGroup.any(
          (item) => item.cells.intersection(candidate.cells).isNotEmpty,
        )) {
      return false;
    }

    for (final selected in selection) {
      final overlaps = selected.pattern.cells
          .intersection(candidate.cells)
          .isNotEmpty;
      if (!overlaps) {
        continue;
      }

      if (group.disallowOverlapWithGroups.contains(selected.groupKey)) {
        return false;
      }
    }

    return true;
  }

  static int _sortScore({
    required bool hasLocalPatternComplete,
    required bool isOneAway,
    required int missingCellCount,
    required int markedCellCount,
  }) {
    final completionScore = hasLocalPatternComplete ? 1000000000 : 0;
    final oneAwayScore = isOneAway ? 100000000 : 0;
    final normalizedMissingCount = missingCellCount < 0
        ? 0
        : missingCellCount > 25
        ? 25
        : missingCellCount;
    final missingScore = (25 - normalizedMissingCount) * 1000000;
    final markedScore = markedCellCount * 1000;

    return completionScore + oneAwayScore + missingScore + markedScore;
  }

  static Map<String, _RuleDefinition> _buildRuleDefinitions() {
    final allRows = [for (var row = 0; row < 5; row++) _rowPattern(row)];
    final allColumns = [
      for (var column = 0; column < 5; column++) _columnPattern(column),
    ];
    final allDiagonals = [_mainDiagonalPattern(), _antiDiagonalPattern()];
    final allLines = [...allRows, ...allColumns, ...allDiagonals];
    final withoutFreeLines = allLines
        .where((candidate) => !candidate.cells.contains(freeCenterCellIndex))
        .toList(growable: false);
    final touchingFreeLines = allLines
        .where((candidate) => candidate.cells.contains(freeCenterCellIndex))
        .toList(growable: false);
    final allSquares = [
      for (var row = 0; row < 4; row++)
        for (var column = 0; column < 4; column++) _squarePattern(row, column),
    ];

    return {
      'FULL_HOUSE': _singlePatternRule('full_house', _allCellsPattern()),
      'ONE_ROW': _countedRule('rows', allRows, 1),
      'ONE_DIAGONAL': _countedRule('diagonals', allDiagonals, 1),
      'MIX_01': _comboRule([
        _RequiredGroup(
          key: 'columns',
          candidates: allColumns,
          requiredCount: 2,
        ),
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 2),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
      'MIX_02': _comboRule([
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 4,
          disallowOverlapWithinGroup: true,
        ),
      ]),
      'MIX_03': _comboRule([
        _RequiredGroup(
          key: 'columns',
          candidates: allColumns,
          requiredCount: 3,
        ),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
      'MIX_04': _comboRule([
        _RequiredGroup(
          key: 'big_t',
          candidates: _bigTPatterns(),
          requiredCount: 1,
        ),
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 2,
          disallowOverlapWithinGroup: true,
          disallowOverlapWithGroups: const {'big_t'},
        ),
      ]),
      'MIX_05': _countedRule('lines', allLines, 5),
      'MIX_06': _countedRule('lines_without_free', withoutFreeLines, 3),
      'MIX_07': _comboRule([
        _RequiredGroup(
          key: 'big_l',
          candidates: _bigLPatterns(),
          requiredCount: 1,
        ),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
      'MIX_08': _comboRule([
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 2),
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 1,
          disallowOverlapWithGroups: const {'rows'},
        ),
      ]),
      'MIX_09': _comboRule([
        _RequiredGroup(
          key: 'columns',
          candidates: allColumns,
          requiredCount: 1,
        ),
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 1),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
      'MIX_10': _countedRule('lines', allLines, 7),
      'MIX_11': _comboRule([
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 3,
          disallowOverlapWithinGroup: true,
        ),
      ]),
      'MIX_12': _countedRule('lines_touching_free', touchingFreeLines, 3),
      'MIX_13': _comboRule([
        _RequiredGroup(
          key: 'columns',
          candidates: allColumns,
          requiredCount: 2,
        ),
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 2),
      ]),
      'BIG_H': _singleChoiceRule('big_h', _bigHPatterns()),
      'HALF_HOUSE_10_DIRECTIONS': _singleChoiceRule(
        'half_house_10',
        _halfHouseTenDirectionPatterns(),
      ),
      'THREE_LINES': _countedRule('lines', allLines, 3),
      'THREE_ROWS_ONE_DIAGONAL': _comboRule([
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 3),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
      'TWO_DIAGONALS_ONE_ROW': _comboRule([
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 2,
        ),
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 1),
      ]),
      'THREE_PARALLEL_LINES': _parallelLinesRule(
        key: 'parallel_lines',
        candidates: [...allRows, ...allColumns],
        count: 3,
      ),
      'FOUR_LINES_WITHOUT_DIAGONAL': _countedRule('lines_without_diagonal', [
        ...allRows,
        ...allColumns,
      ], 4),
      'HALF_HOUSE_4_DIRECTIONS': _singleChoiceRule(
        'half_house_4',
        _halfHouseFourDirectionPatterns(),
      ),
      'MIX_14': _comboRule([
        _RequiredGroup(
          key: 'touching_free',
          candidates: touchingFreeLines,
          requiredCount: 1,
        ),
        _RequiredGroup(
          key: 'without_free',
          candidates: withoutFreeLines,
          requiredCount: 2,
        ),
      ]),
      'BIG_CROSS_ONE_DIAGONAL': _comboRule([
        _RequiredGroup(
          key: 'big_cross',
          candidates: [_bigCrossPattern()],
          requiredCount: 1,
        ),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
      'TWO_ROWS_ONE_SQUARE_ALT': _comboRule([
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 2),
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 1,
          disallowOverlapWithGroups: const {'rows'},
        ),
      ]),
      'SIX_LINES': _countedRule('lines', allLines, 6),
      'THREE_COLUMNS': _countedRule('columns', allColumns, 3),
      'FOUR_PARALLEL_LINES': _parallelLinesRule(
        key: 'parallel_lines',
        candidates: [...allRows, ...allColumns],
        count: 4,
      ),
      'FOUR_ANGLES_TWO_SQUARES': _comboRule([
        _RequiredGroup(
          key: 'angles',
          candidates: [_fourCornersPattern()],
          requiredCount: 1,
        ),
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 2,
          disallowOverlapWithinGroup: true,
          disallowOverlapWithGroups: const {'angles'},
        ),
      ]),
      'FOUR_LINES': _countedRule('lines', allLines, 4),
      'THREE_ROWS': _countedRule('rows', allRows, 3),
      'TWO_ROWS_ONE_COLUMN': _comboRule([
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 2),
        _RequiredGroup(
          key: 'columns',
          candidates: allColumns,
          requiredCount: 1,
        ),
      ]),
      'TWO_DIAGONALS': _countedRule('diagonals', allDiagonals, 2),
      'ONE_COLUMN_ONE_ROW_ONE_SQUARE': _comboRule([
        _RequiredGroup(
          key: 'columns',
          candidates: allColumns,
          requiredCount: 1,
        ),
        _RequiredGroup(key: 'rows', candidates: allRows, requiredCount: 1),
        _RequiredGroup(
          key: 'squares',
          candidates: allSquares,
          requiredCount: 1,
          disallowOverlapWithGroups: const {'columns', 'rows'},
        ),
      ]),
      'BIG_T_ONE_DIAGONAL': _comboRule([
        _RequiredGroup(
          key: 'big_t',
          candidates: _bigTPatterns(),
          requiredCount: 1,
        ),
        _RequiredGroup(
          key: 'diagonals',
          candidates: allDiagonals,
          requiredCount: 1,
        ),
      ]),
    };
  }

  static _RuleDefinition _singlePatternRule(
    String key,
    _CandidatePattern pattern,
  ) {
    return _comboRule([
      _RequiredGroup(key: key, candidates: [pattern], requiredCount: 1),
    ]);
  }

  static _RuleDefinition _singleChoiceRule(
    String key,
    List<_CandidatePattern> patterns,
  ) {
    return _comboRule([
      _RequiredGroup(key: key, candidates: patterns, requiredCount: 1),
    ]);
  }

  static _RuleDefinition _countedRule(
    String key,
    List<_CandidatePattern> candidates,
    int count,
  ) {
    return _comboRule([
      _RequiredGroup(key: key, candidates: candidates, requiredCount: count),
    ]);
  }

  static _RuleDefinition _parallelLinesRule({
    required String key,
    required List<_CandidatePattern> candidates,
    required int count,
  }) {
    return _comboRule([
      _RequiredGroup(
        key: key,
        candidates: candidates,
        requiredCount: count,
        requireSameOrientation: true,
      ),
    ]);
  }

  static _RuleDefinition _comboRule(List<_RequiredGroup> groups) {
    return _RuleDefinition(groups: groups);
  }

  static Set<int> markedCellIndexes({
    required List<List<String>> columns,
    required Set<String> manualMarkedNumbers,
  }) {
    final markedIndexes = <int>{};
    for (
      var columnIndex = 0;
      columnIndex < bingoColumnHeaders.length;
      columnIndex++
    ) {
      final header = bingoColumnHeaders[columnIndex];
      final column = columns[columnIndex];
      for (var rowIndex = 0; rowIndex < column.length; rowIndex++) {
        final value = column[rowIndex];
        if (isManuallyMarkedCell(
          manualMarkedNumbers: manualMarkedNumbers,
          header: header,
          value: value,
        )) {
          markedIndexes.add((rowIndex * 5) + columnIndex);
        }
      }
    }

    return markedIndexes;
  }

  static String? cellValueAt({
    required List<List<String>> columns,
    required int cellIndex,
  }) {
    final row = cellIndex ~/ 5;
    final column = cellIndex % 5;
    if (column >= columns.length || row >= columns[column].length) {
      return null;
    }

    return columns[column][row];
  }

  static _CandidatePattern _allCellsPattern() {
    return _CandidatePattern(
      id: 'all_cells',
      cells: {for (var index = 0; index < 25; index++) index},
    );
  }

  static _CandidatePattern _rowPattern(int row) {
    return _CandidatePattern(
      id: 'row_$row',
      cells: {for (var column = 0; column < 5; column++) (row * 5) + column},
      orientation: 'row',
    );
  }

  static _CandidatePattern _columnPattern(int column) {
    return _CandidatePattern(
      id: 'column_$column',
      cells: {for (var row = 0; row < 5; row++) (row * 5) + column},
      orientation: 'column',
    );
  }

  static _CandidatePattern _mainDiagonalPattern() {
    return _CandidatePattern(
      id: 'diag_main',
      cells: {for (var index = 0; index < 5; index++) (index * 5) + index},
      orientation: 'diagonal',
    );
  }

  static _CandidatePattern _antiDiagonalPattern() {
    return _CandidatePattern(
      id: 'diag_anti',
      cells: {
        for (var index = 0; index < 5; index++) (index * 5) + (4 - index),
      },
      orientation: 'diagonal',
    );
  }

  static _CandidatePattern _squarePattern(int row, int column) {
    return _CandidatePattern(
      id: 'square_${row}_$column',
      cells: {
        (row * 5) + column,
        (row * 5) + column + 1,
        ((row + 1) * 5) + column,
        ((row + 1) * 5) + column + 1,
      },
    );
  }

  static List<_CandidatePattern> _bigLPatterns() {
    return BigShapePatterns.bigLVariants
        .map(
          (variant) =>
              _CandidatePattern(id: variant.id, cells: variant.cells),
        )
        .toList(growable: false);
  }

  static List<_CandidatePattern> _bigTPatterns() {
    return BigShapePatterns.bigTVariants
        .map(
          (variant) =>
              _CandidatePattern(id: variant.id, cells: variant.cells),
        )
        .toList(growable: false);
  }

  static List<_CandidatePattern> _bigHPatterns() {
    return BigShapePatterns.bigHVariants
        .map(
          (variant) =>
              _CandidatePattern(id: variant.id, cells: variant.cells),
        )
        .toList(growable: false);
  }

  static _CandidatePattern _bigCrossPattern() {
    return _CandidatePattern(
      id: 'big_cross',
      cells: _coords([
        [2, 0],
        [2, 1],
        [2, 2],
        [2, 3],
        [2, 4],
        [0, 2],
        [1, 2],
        [3, 2],
        [4, 2],
      ]),
    );
  }

  static _CandidatePattern _fourCornersPattern() {
    return const _CandidatePattern(
      id: 'four_corners',
      cells: {0, 4, 20, 24},
    );
  }

  static List<_CandidatePattern> _halfHouseFourDirectionPatterns() {
    return const [
          (
            'half_house_tr',
            [
              [0, 0],
              [0, 1],
              [0, 2],
              [0, 3],
              [0, 4],
              [1, 1],
              [1, 2],
              [1, 3],
              [1, 4],
              [2, 2],
              [2, 3],
              [2, 4],
              [3, 3],
              [3, 4],
              [4, 4],
            ],
          ),
          (
            'half_house_tl',
            [
              [0, 0],
              [0, 1],
              [0, 2],
              [0, 3],
              [0, 4],
              [1, 0],
              [1, 1],
              [1, 2],
              [1, 3],
              [2, 0],
              [2, 1],
              [2, 2],
              [3, 0],
              [3, 1],
              [4, 0],
            ],
          ),
          (
            'half_house_bl',
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
              [4, 0],
              [4, 1],
              [4, 2],
              [4, 3],
              [4, 4],
            ],
          ),
          (
            'half_house_br',
            [
              [0, 4],
              [1, 3],
              [1, 4],
              [2, 2],
              [2, 3],
              [2, 4],
              [3, 1],
              [3, 2],
              [3, 3],
              [3, 4],
              [4, 0],
              [4, 1],
              [4, 2],
              [4, 3],
              [4, 4],
            ],
          ),
        ]
        .map(
          (entry) => _CandidatePattern(id: entry.$1, cells: _coords(entry.$2)),
        )
        .toList(growable: false);
  }

  static List<_CandidatePattern> _halfHouseTenDirectionPatterns() {
    return [
      ..._halfHouseFourDirectionPatterns(),
      _CandidatePattern(
        id: 'half_house_top',
        cells: {for (var row = 0; row < 3; row++) ..._rowPattern(row).cells},
      ),
      _CandidatePattern(
        id: 'half_house_middle_rows',
        cells: {for (var row = 1; row < 4; row++) ..._rowPattern(row).cells},
      ),
      _CandidatePattern(
        id: 'half_house_bottom',
        cells: {for (var row = 2; row < 5; row++) ..._rowPattern(row).cells},
      ),
      _CandidatePattern(
        id: 'half_house_left',
        cells: {
          for (var column = 0; column < 3; column++)
            ..._columnPattern(column).cells,
        },
      ),
      _CandidatePattern(
        id: 'half_house_middle_columns',
        cells: {
          for (var column = 1; column < 4; column++)
            ..._columnPattern(column).cells,
        },
      ),
      _CandidatePattern(
        id: 'half_house_right',
        cells: {
          for (var column = 2; column < 5; column++)
            ..._columnPattern(column).cells,
        },
      ),
    ];
  }

  static Set<int> _coords(List<List<int>> pairs) {
    return pairs.map((pair) => (pair[0] * 5) + pair[1]).toSet();
  }
}

int markedCellCount({
  required Set<String> manualMarkedNumbers,
  required List<List<String>> columns,
}) {
  return CartelaMarkedPatternEvaluator.markedCellIndexes(
    columns: columns,
    manualMarkedNumbers: manualMarkedNumbers,
  ).length;
}

class _RuleDefinition {
  const _RuleDefinition({required this.groups});

  final List<_RequiredGroup> groups;
}

class _RequiredGroup {
  const _RequiredGroup({
    required this.key,
    required this.candidates,
    required this.requiredCount,
    this.disallowOverlapWithinGroup = false,
    this.disallowOverlapWithGroups = const {},
    this.requireSameOrientation = false,
  });

  final String key;
  final List<_CandidatePattern> candidates;
  final int requiredCount;
  final bool disallowOverlapWithinGroup;
  final Set<String> disallowOverlapWithGroups;
  final bool requireSameOrientation;
}

class _CandidatePattern {
  const _CandidatePattern({
    required this.id,
    required this.cells,
    this.orientation,
  });

  final String id;
  final Set<int> cells;
  final String? orientation;
}

class _SelectedPattern {
  const _SelectedPattern({required this.groupKey, required this.pattern});

  final String groupKey;
  final _CandidatePattern pattern;
}

class _BestSelection {
  const _BestSelection({
    required this.markedIndexes,
    required this.missingCells,
    required this.selectedPatterns,
  });

  final Set<int> markedIndexes;
  final Set<int> missingCells;
  final List<_SelectedPattern> selectedPatterns;

  int get missingCellCount => missingCells.length;

  Set<int> get coveredCells {
    return {for (final selected in selectedPatterns) ...selected.pattern.cells};
  }

  Iterable<_SelectedPattern> get _completedMarkedPatterns {
    return selectedPatterns.where(
      (selected) => selected.pattern.cells.difference(markedIndexes).isEmpty,
    );
  }

  int get completedPatternCount => _completedMarkedPatterns.length;

  int get matchedMarkedCellCount {
    return selectedPatterns.fold(
      0,
      (count, selected) =>
          count + selected.pattern.cells.intersection(markedIndexes).length,
    );
  }

  CartelaPatternProgressOverlay get trackedPatternOverlay {
    return CartelaPatternProgressOverlay.merge(
      _completedMarkedPatterns.map(
        (selected) => (
          patternId: selected.pattern.id,
          cells: selected.pattern.cells,
        ),
      ),
    );
  }

  bool isBetterThan(_BestSelection other) {
    if (missingCellCount != other.missingCellCount) {
      return missingCellCount < other.missingCellCount;
    }

    if (completedPatternCount != other.completedPatternCount) {
      return completedPatternCount > other.completedPatternCount;
    }

    if (matchedMarkedCellCount != other.matchedMarkedCellCount) {
      return matchedMarkedCellCount > other.matchedMarkedCellCount;
    }

    return false;
  }

  bool isEquivalentTo(_BestSelection other) {
    return missingCellCount == other.missingCellCount &&
        completedPatternCount == other.completedPatternCount &&
        matchedMarkedCellCount == other.matchedMarkedCellCount;
  }

}

class _SelectionSearchResult {
  const _SelectionSearchResult({
    required this.bestSelection,
    required this.tiedBestSelections,
  });

  final _BestSelection? bestSelection;
  final List<_BestSelection> tiedBestSelections;

  Set<int> get oneAwayCellIndexes {
    return {
      for (final selection in tiedBestSelections)
        if (selection.missingCells.length == 1) selection.missingCells.first,
    };
  }
}
