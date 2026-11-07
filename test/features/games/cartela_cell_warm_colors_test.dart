import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets(
    'CartelaBoardWidget cells use warm cream for unmarked, emerald green for marked, and noticeable subtle BINGO headers',
    (tester) async {
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

      // Cell 0 has number 9 (marked), Cell 1 has number 4 (unmarked)
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: const [LivePlayThemeTokens.light],
          ),
          home: Scaffold(
            body: Center(
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

      // Check B-I-N-G-O header letter pills
      for (final letter in ['B', 'I', 'N', 'G', 'O']) {
        final textFinder = find.text(letter);
        expect(textFinder, findsOneWidget);
        // Ensure each letter is wrapped with a FittedBox to guarantee zero vertical/horizontal clipping
        final fittedBoxFinder = find.ancestor(
          of: textFinder,
          matching: find.byType(FittedBox),
        );
        expect(fittedBoxFinder, findsWidgets);
      }

      // Find animated containers representing cells
      final cellContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(cellContainers.isNotEmpty, isTrue);

      // First cell ('9', marked) decoration fill is emerald green
      final markedDecoration = cellContainers.first.decoration as BoxDecoration;
      expect(markedDecoration.color, const Color(0xFF27AE60));

      // Second cell ('4', unmarked) decoration fill is warm cream (#F5EFE6), NOT Colors.white
      final unmarkedDecoration =
          cellContainers.elementAt(1).decoration as BoxDecoration;
      expect(unmarkedDecoration.color, const Color(0xFFF5EFE6));
      expect(unmarkedDecoration.color, isNot(equals(Colors.white)));
    },
  );
}
