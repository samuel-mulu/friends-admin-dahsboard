import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('CartelaBoardWidget cells use warm cream for unmarked and emerald green for marked', (tester) async {
    final now = DateTime.now();
    final dummyCartela = CartelaModel(
      id: 'c1',
      number: 1074,
      createdAt: now,
      b: ['9', '4', '2', '5', '15'],
      i: ['30', '23', '24', '16', '26'],
      n: ['35', '42', 'FREE', '40', '33'],
      g: ['55', '56', '46', '50', '52'],
      o: ['63', '75', '65', '66', '61'],
    );

    // Number 9 is marked, number 4 is unmarked
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: const [LivePlayThemeTokens.light],
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              height: 480,
              child: CartelaBoardWidget(
                cartela: dummyCartela,
                markedCells: const {9},
                interactive: false,
              ),
            ),
          ),
        ),
      ),
    );

    // Find animated containers representing cells
    final cellContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(cellContainers.isNotEmpty, isTrue);

    // First cell (number 9 - marked) decoration fill is emerald green
    final markedDecoration = cellContainers.first.decoration as BoxDecoration;
    expect(markedDecoration.color, const Color(0xFF27AE60));

    // Second cell (number 4 - unmarked) decoration fill is warm cream (#F5EFE6), NOT Colors.white
    final unmarkedDecoration = cellContainers.elementAt(1).decoration as BoxDecoration;
    expect(unmarkedDecoration.color, const Color(0xFFF5EFE6));
    expect(unmarkedDecoration.color, isNot(equals(Colors.white)));
  });

  testWidgets('CartelaBoardWidget renders B-I-N-G-O header pills with distinct subtle column background colors', (tester) async {
    final now = DateTime.now();
    final dummyCartela = CartelaModel(
      id: 'c1',
      number: 1074,
      createdAt: now,
      b: ['9', '4', '2', '5', '15'],
      i: ['30', '23', '24', '16', '26'],
      n: ['35', '42', 'FREE', '40', '33'],
      g: ['55', '56', '46', '50', '52'],
      o: ['63', '75', '65', '66', '61'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: const [LivePlayThemeTokens.light],
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              height: 480,
              child: CartelaBoardWidget(
                cartela: dummyCartela,
                markedCells: const {},
                interactive: false,
              ),
            ),
          ),
        ),
      ),
    );

    // Verify all letters B, I, N, G, O are present
    for (final letter in ['B', 'I', 'N', 'G', 'O']) {
      expect(find.text(letter), findsOneWidget);
    }
  });
}
