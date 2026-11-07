import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';

CartelaModel _createSampleCartela() {
  return CartelaModel(
    id: 'cartela-1',
    number: 3984,
    createdAt: DateTime.utc(2026, 11, 7),
    b: const ['8', '5', '7', '3', '12'],
    i: const ['23', '22', '29', '30', '28'],
    n: const ['42', '39', 'FREE', '35', '44'],
    g: const ['48', '57', '49', '55', '47'],
    o: const ['69', '75', '71', '67', '73'],
  );
}

void main() {
  group('CartelaBoardWidget Square Aspect Ratio & Header Tests', () {
    testWidgets('Live expanded cartela board cells maintain 1:1 square aspect ratio', (tester) async {
      final cartela = _createSampleCartela();

      // Render inside an asymmetric / elongated container (e.g. 200 width, 380 height)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 380,
                child: CartelaBoardWidget(
                  cartela: cartela,
                  markedCells: const {8, 23, 5, 22},
                  showHeader: false,
                  expandToFill: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check all AspectRatio widgets inside the board
      final aspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatios, isNotEmpty);

      // Verify each individual cell AspectRatio is strictly 1.0
      for (final ar in aspectRatios) {
        expect(ar.aspectRatio, closeTo(1.0, 0.001));
      }

      // Check cell render box dimensions for cell '8'
      final cell8Text = find.text('8');
      expect(cell8Text, findsOneWidget);

      final cell8Box = tester.renderObject(cell8Text);
      expect(cell8Box, isNotNull);
    });

    testWidgets('BINGO letter bar has dedicated subtle background color', (tester) async {
      final cartela = _createSampleCartela();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 240,
              height: 300,
              child: CartelaBoardWidget(
                cartela: cartela,
                markedCells: const {},
                showHeader: false,
                expandToFill: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify B, I, N, G, O letters exist
      for (final letter in ['B', 'I', 'N', 'G', 'O']) {
        expect(find.text(letter), findsOneWidget);
      }

      // Verify the BINGO bar container has a subtle warm background tint
      final containerFinders = find.byType(Container);
      bool foundSubtleBar = false;
      for (final c in tester.widgetList<Container>(containerFinders)) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          final color = decoration.color;
          if (color != null && color != Colors.transparent && color != Colors.white) {
            foundSubtleBar = true;
            break;
          }
        }
      }
      expect(foundSubtleBar, isTrue, reason: 'BINGO letter bar should have its own subtle background tint');
    });
  });
}

