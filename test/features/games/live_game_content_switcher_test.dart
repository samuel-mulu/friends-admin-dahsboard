import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/live_game_content_switcher.dart';

void main() {
  group('LiveGameContentSwitcher Tests', () {
    testWidgets('renders child directly on initial paint without animation delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveGameContentSwitcher(
              transitionKey: 'registration-1',
              hasCompletedInitialPaint: false,
              child: Text('Registration View'),
            ),
          ),
        ),
      );

      expect(find.text('Registration View'), findsOneWidget);
    });

    testWidgets('fades smoothly to new child when transitionKey changes', (
      tester,
    ) async {
      var currentKey = 'registration-1';
      var text = 'Registration View';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentKey = 'live-1';
                          text = 'Live Game View';
                        });
                      },
                      child: const Text('Switch'),
                    ),
                    Expanded(
                      child: LiveGameContentSwitcher(
                        transitionKey: currentKey,
                        hasCompletedInitialPaint: true,
                        child: Text(text),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Registration View'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pump(); // Start transition animation
      await tester.pump(const Duration(milliseconds: 120)); // Mid-transition

      expect(find.text('Live Game View'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150)); // Completed 240ms transition
      await tester.pumpAndSettle();

      expect(find.text('Live Game View'), findsOneWidget);
      expect(find.text('Registration View'), findsNothing);
    });
  });
}
