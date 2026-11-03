import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';

final _now = DateTime.utc(2026, 3, 1);

CartelaModel _sampleCartela() {
  List<String> column(int col) => [
    for (var row = 0; row < 5; row++)
      row == 2 && col == 2 ? 'FREE' : '${col * 15 + row + 1}',
  ];

  return CartelaModel(
    id: 'cartela-1',
    number: 42,
    createdAt: _now,
    b: column(0),
    i: column(1),
    n: column(2),
    g: column(3),
    o: column(4),
  );
}

void main() {
  testWidgets('scrolling visual tier builds without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 280,
            child: CartelaBoardWidget(
              cartela: _sampleCartela(),
              markedCells: const {1, 2},
              showHeader: false,
              expandToFill: true,
              visualTier: CartelaVisualTier.scrolling,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CartelaBoardWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
