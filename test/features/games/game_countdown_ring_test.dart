import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/game_countdown_ring.dart';

void main() {
  testWidgets('GameCountdownRing formats remaining seconds and applies label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameCountdownRing(
            remaining: Duration(seconds: 45),
            total: Duration(seconds: 60),
            label: 'Starts in',
          ),
        ),
      ),
    );

    expect(find.text('45'), findsOneWidget);
    expect(find.text('Starts in'), findsOneWidget);
  });

  testWidgets('GameCountdownRing formats minutes when showMinutes is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameCountdownRing(
            remaining: Duration(seconds: 125),
            total: Duration(seconds: 180),
            showMinutes: true,
          ),
        ),
      ),
    );

    expect(find.text('02:05'), findsOneWidget);
  });
}
