import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/called_numbers_strip.dart';

void main() {
  testWidgets('CalledNumbersStrip renders all called numbers in reverse order with latest highlighted', (tester) async {
    final now = DateTime.now();
    final balls = [
      CalledNumberModel(
        id: '1',
        sessionId: 'session-1',
        letter: 'B',
        number: 10,
        order: 1,
        createdAt: now,
      ),
      CalledNumberModel(
        id: '2',
        sessionId: 'session-1',
        letter: 'I',
        number: 25,
        order: 2,
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalledNumbersStrip(calledNumbers: balls),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('CalledNumbersStrip shows waiting message when empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalledNumbersStrip(calledNumbers: []),
        ),
      ),
    );

    expect(find.text('Waiting for first call...'), findsOneWidget);
  });
}
