import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_claim_button.dart';

void main() {
  testWidgets('BingoClaimButton renders BINGO text and triggers onPressed when enabled', (tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BingoClaimButton(
            canClaim: true,
            showReadyPulse: false,
            isClaiming: false,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('BINGO'), findsOneWidget);
    await tester.tap(find.text('BINGO'));
    expect(pressed, isTrue);
  });

  testWidgets('BingoClaimButton displays CircularProgressIndicator when claiming', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BingoClaimButton(
            canClaim: true,
            showReadyPulse: false,
            isClaiming: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('BINGO'), findsNothing);
  });

  testWidgets('BingoClaimButton debounces multiple rapid taps and includes accessibility semantics', (tester) async {
    int pressCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BingoClaimButton(
            canClaim: true,
            showReadyPulse: true,
            isClaiming: false,
            onPressed: () => pressCount++,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Claim Bingo',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('BINGO'));
    await tester.tap(find.text('BINGO'));
    expect(pressCount, 1);
  });
}
