import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'cartela_board_widget.dart';

/// Placeholder columns for instant B-I-N-G-O chrome while board numbers load.
List<List<String>> emptyCartelaBoardColumns() => [
  ['', '', '', '', ''],
  ['', '', '', '', ''],
  ['', '', 'FREE', '', ''],
  ['', '', '', '', ''],
  ['', '', '', '', ''],
];

/// Read-only B-I-N-G-O grid for cartela preview modals delegating to [CartelaBoardWidget].
class CartelaBoardPreview extends StatelessWidget {
  const CartelaBoardPreview({
    required this.columns,
    this.calledNumbers = const <int>{},
    super.key,
  });

  final List<List<String>> columns;

  /// Session called ball numbers — cells whose value is in this set are marked
  /// (same rule as admin game-history cartela expand).
  final Set<int> calledNumbers;

  @override
  Widget build(BuildContext context) {
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
      markedCells: calledNumbers,
      showHeader: false,
      interactive: false,
    );
  }
}
