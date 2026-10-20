import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_ball_badge.dart';

void main() {
  group('BingoBallBadge Tests', () {
    testWidgets('derives B for number 12 and applies correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BingoBallBadge(number: 12)),
        ),
      );
      expect(find.text('B'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('derives O for number 75', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BingoBallBadge(number: 75)),
        ),
      );
      expect(find.text('O'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    test('static helper derives correct letters and colors for all ranges', () {
      expect(BingoBallBadge.getLetter(1), 'B');
      expect(BingoBallBadge.getLetter(15), 'B');
      expect(BingoBallBadge.getLetter(16), 'I');
      expect(BingoBallBadge.getLetter(30), 'I');
      expect(BingoBallBadge.getLetter(31), 'N');
      expect(BingoBallBadge.getLetter(45), 'N');
      expect(BingoBallBadge.getLetter(46), 'G');
      expect(BingoBallBadge.getLetter(60), 'G');
      expect(BingoBallBadge.getLetter(61), 'O');
      expect(BingoBallBadge.getLetter(75), 'O');

      expect(BingoBallBadge.getColor(5), const Color(0xFFE53935)); // B
      expect(BingoBallBadge.getColor(20), const Color(0xFFFB8C00)); // I
      expect(BingoBallBadge.getColor(35), const Color(0xFF1E88E5)); // N
      expect(BingoBallBadge.getColor(50), const Color(0xFF43A047)); // G
      expect(BingoBallBadge.getColor(65), const Color(0xFF8E24AA)); // O
    });
  });
}
