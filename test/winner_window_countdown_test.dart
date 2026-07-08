import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:friends_bingo_app/src/features/games/presentation/widgets/winner_window_countdown.dart';

void main() {
  testWidgets('shows remaining seconds on first frame', (tester) async {
    final endsAt = DateTime.now().add(const Duration(seconds: 25));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WinnerWindowCountdown(endsAt: endsAt),
        ),
      ),
    );

    expect(find.textContaining('Winner window closes in'), findsOneWidget);
    expect(find.textContaining('25s'), findsOneWidget);
    expect(find.text('Finalizing...'), findsNothing);
  });

  testWidgets('updates when endsAt changes', (tester) async {
    var endsAt = DateTime.now().add(const Duration(seconds: 10));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return WinnerWindowCountdown(endsAt: endsAt);
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('10s'), findsOneWidget);

    endsAt = DateTime.now().add(const Duration(seconds: 18));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WinnerWindowCountdown(endsAt: endsAt),
        ),
      ),
    );

    expect(find.textContaining('18s'), findsOneWidget);
  });
}
