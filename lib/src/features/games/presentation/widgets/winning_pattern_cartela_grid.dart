import 'package:flutter/material.dart';

import '../../data/models/cartela_model.dart';
import '../components/cartela_board_widget.dart';
import '../utils/cartela_pattern_progress_overlay.dart';

/// Read-only B-I-N-G-O winning pattern board for review sheets and winner modals,
/// delegating to the unified [CartelaBoardWidget].
class WinningPatternCartelaGrid extends StatelessWidget {
  const WinningPatternCartelaGrid({
    required this.columns,
    required this.highlightCellIndexes,
    this.patternOverlay = const CartelaPatternProgressOverlay(),
    this.winningBallCellIndex,
    this.calledNumbers = const <int>{},
    this.compact = false,
    super.key,
  });

  final List<List<String>> columns;
  final Set<int> highlightCellIndexes;
  final CartelaPatternProgressOverlay patternOverlay;
  final int? winningBallCellIndex;

  /// Session called ball numbers — non-pattern cells still show as marked
  /// (same rule as admin game-history cartela expand).
  final Set<int> calledNumbers;
  final bool compact;

  Set<int> get _effectiveHighlightCellIndexes {
    if (highlightCellIndexes.isNotEmpty) {
      return highlightCellIndexes;
    }
    if (!patternOverlay.isEmpty) {
      return patternOverlay.allOverlayCellIndexes;
    }
    return highlightCellIndexes;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHighlights = _effectiveHighlightCellIndexes;
    final winningNumbers = <int>{};
    int? winningBallNum;

    for (int col = 0; col < columns.length; col++) {
      for (int row = 0; row < columns[col].length; row++) {
        final cellIdx = (row * 5) + col;
        final rawVal = columns[col][row];
        final number = int.tryParse(rawVal) ?? 0;
        if (number > 0) {
          if (effectiveHighlights.contains(cellIdx)) {
            winningNumbers.add(number);
          }
          if (winningBallCellIndex != null && winningBallCellIndex == cellIdx) {
            winningBallNum = number;
          }
        }
      }
    }

    final allMarked = <int>{...winningNumbers, ...calledNumbers};

    return CartelaBoardWidget(
      cartela: CartelaModel(
        id: '',
        number: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        b: columns.isNotEmpty ? columns[0] : const [],
        i: columns.length > 1 ? columns[1] : const [],
        n: columns.length > 2 ? columns[2] : const [],
        g: columns.length > 3 ? columns[3] : const [],
        o: columns.length > 4 ? columns[4] : const [],
      ),
      markedCells: allMarked,
      winningPatternCells: winningNumbers,
      winningBallNumber: winningBallNum,
      patternOverlay: patternOverlay,
      isWinner: true,
      showHeader: false,
      interactive: false,
    );
  }
}
