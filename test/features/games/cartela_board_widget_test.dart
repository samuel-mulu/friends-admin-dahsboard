import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/cartela_board_widget.dart';

void main() {
  final sampleCartela = CartelaModel(
    id: 'test-cartela-1',
    number: 42,
    createdAt: DateTime.now(),
    b: const ['1', '2', '3', '4', '5'],
    i: const ['16', '17', '18', '19', '20'],
    n: const ['31', '32', '0', '34', '35'], // '0' is Free Space
    g: const ['46', '47', '48', '49', '50'],
    o: const ['61', '62', '63', '64', '65'],
  );

  testWidgets('CartelaBoardWidget renders B-I-N-G-O headers and numbers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaBoardWidget(
            cartela: sampleCartela,
            markedCells: const {1, 16},
          ),
        ),
      ),
    );

    expect(find.text('B'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget); // Card header number
    expect(find.text('FREE'), findsOneWidget); // Center Free space
  });

  testWidgets('CartelaBoardWidget triggers onCellTapped callback on number tap', (tester) async {
    int? tappedNumber;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaBoardWidget(
            cartela: sampleCartela,
            markedCells: const {},
            onCellTapped: (num) => tappedNumber = num,
          ),
        ),
      ),
    );

    await tester.tap(find.text('1'));
    expect(tappedNumber, 1);
  });
}
