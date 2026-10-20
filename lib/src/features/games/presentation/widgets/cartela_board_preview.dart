import 'package:flutter/material.dart';

import '../../data/models/cartela_model.dart';
import '../components/cartela_board_widget.dart';

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
    super.key,
  });

  final List<List<String>> columns;

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
      markedCells: const {},
      showHeader: false,
      interactive: false,
    );
  }
}

