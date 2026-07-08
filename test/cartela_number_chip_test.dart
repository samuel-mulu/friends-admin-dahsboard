import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/features/games/domain/cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_number_chip.dart';

Widget _chip({
  required CartelaAvailability availability,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool selectModeEnabled = false,
  bool isSelected = false,
  int? reservationSecondsRemaining,
}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: CartelaNumberChip(
        number: 12,
        availability: availability,
        reservationSecondsRemaining: reservationSecondsRemaining,
        selectModeEnabled: selectModeEnabled,
        isSelected: isSelected,
        onTap: onTap ?? () {},
        onLongPress: onLongPress,
      ),
    ),
  );
}

Decoration _chipDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(CartelaNumberChip),
      matching: find.byType(Container).first,
    ),
  );
  return container.decoration!;
}

void main() {
  testWidgets('available chip uses primary brand styling', (tester) async {
    await tester.pumpWidget(_chip(availability: CartelaAvailability.available));

    final decoration = _chipDecoration(tester);
    expect(decoration, isA<BoxDecoration>());
    final boxDecoration = decoration as BoxDecoration;
    expect(boxDecoration.color, AppBranding.cartelaChipAvailableBackground(
      tester.element(find.byType(CartelaNumberChip)),
    ));
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('mine and taken chips keep status labels', (tester) async {
    await tester.pumpWidget(_chip(availability: CartelaAvailability.mine));
    expect(find.text('Yours'), findsOneWidget);

    await tester.pumpWidget(_chip(availability: CartelaAvailability.taken));
    expect(find.text('Taken'), findsOneWidget);

    await tester.pumpWidget(
      _chip(availability: CartelaAvailability.reservedByOther),
    );
    expect(find.text('Res'), findsOneWidget);
  });

  testWidgets('select mode shows number on selected chip, not hold countdown',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaNumberChip(
            number: 12,
            availability: CartelaAvailability.reservedByMe,
            reservationSecondsRemaining: 8,
            selectModeEnabled: true,
            isSelected: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('8s'), findsNothing);
  });

  testWidgets('pending bulk selection shows loading ring not countdown badge',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaNumberChip(
            number: 9,
            availability: CartelaAvailability.available,
            selectModeEnabled: true,
            isSelected: true,
            isReservePending: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('9'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('8s'), findsNothing);
  });

  testWidgets('confirmed bulk hold shows countdown badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaNumberChip(
            number: 9,
            availability: CartelaAvailability.reservedByMe,
            reservationSecondsRemaining: 8,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('9'), findsOneWidget);
    expect(find.text('8s'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('select mode allows tap to deselect held chip', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaNumberChip(
            number: 7,
            availability: CartelaAvailability.reservedByMe,
            reservationSecondsRemaining: 5,
            selectModeEnabled: true,
            isSelected: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CartelaNumberChip));
    expect(tapped, isTrue);
  });

  testWidgets('long press on available chip invokes onLongPress', (tester) async {
    var longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaNumberChip(
            number: 42,
            availability: CartelaAvailability.available,
            onTap: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(CartelaNumberChip));
    expect(longPressed, isTrue);
  });

  testWidgets('long press is disabled in select mode', (tester) async {
    var longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaNumberChip(
            number: 42,
            availability: CartelaAvailability.available,
            selectModeEnabled: true,
            onTap: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(CartelaNumberChip));
    expect(longPressed, isFalse);
  });
}
