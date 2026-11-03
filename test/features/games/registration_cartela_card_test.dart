import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_cartela_card.dart';

void main() {
  group('RegistrationCartelaCard', () {
    testWidgets('renders in tile mode and handles tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: RegistrationCartelaCard(
                  number: 42,
                  availability: CartelaAvailability.available,
                  displayMode: RegistrationCartelaDisplayMode.tile,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      await tester.tap(find.text('42'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders in card mode with subtitle and status badge', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: RegistrationCartelaCard(
                  number: 99,
                  availability: CartelaAvailability.available,
                  displayMode: RegistrationCartelaDisplayMode.card,
                  entryFee: '10 ETB',
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cartela #99'), findsOneWidget);
      expect(find.text('Fee: 10 ETB'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);

      await tester.tap(find.text('Cartela #99'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders checkbox in selectModeEnabled', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: RegistrationCartelaCard(
                  number: 15,
                  availability: CartelaAvailability.available,
                  displayMode: RegistrationCartelaDisplayMode.card,
                  selectModeEnabled: true,
                  isSelected: true,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
