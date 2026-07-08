import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/bulk_register_result.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/bulk_cartela_review_sheet.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/removable_cartela_number_chip.dart';

CartelaModel _cartela(int number) {
  return CartelaModel(
    id: 'cartela-$number',
    number: number,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('BulkCartelaReviewSheet', () {
    testWidgets('renders a removable chip for each selected cartela', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34), _cartela(56)],
            entryFee: '10',
            onRegister: (_, __) async =>
                const BulkRegisterResult(successes: [], failures: []),
          ),
        ),
      );

      expect(find.byType(RemovableCartelaNumberChip), findsNWidgets(3));
      expect(find.text('#12'), findsOneWidget);
      expect(find.text('#34'), findsOneWidget);
      expect(find.text('#56'), findsOneWidget);
      expect(find.textContaining('3 cartelas'), findsOneWidget);
    });

    testWidgets('remove button drops chip and notifies parent', (tester) async {
      CartelaModel? removed;

      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34)],
            entryFee: '10',
            onCartelaRemoved: (cartela) => removed = cartela,
            onRegister: (_, __) async =>
                const BulkRegisterResult(successes: [], failures: []),
          ),
        ),
      );

      final removeButtons = find.byIcon(Icons.close_rounded);
      expect(removeButtons, findsNWidgets(2));

      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('#12'), findsNothing);
      expect(find.text('#34'), findsOneWidget);
      expect(find.textContaining('1 cartelas'), findsOneWidget);
      expect(removed?.number, 12);
    });

    testWidgets('register is disabled when all cartelas are removed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(34)],
            entryFee: '10',
            onRegister: (_, __) async =>
                const BulkRegisterResult(successes: [], failures: []),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(
        find.text('Select at least one cartela to register.'),
        findsWidgets,
      );
      final registerButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Register 0'),
      );
      expect(registerButton.onPressed, isNull);
    });

    testWidgets('register stays enabled for remaining cartelas', (
      tester,
    ) async {
      var registerCalled = false;

      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34)],
            entryFee: '10',
            onRegister: (_, __) async {
              registerCalled = true;
              return const BulkRegisterResult(successes: [], failures: []);
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Register 1'));
      await tester.pumpAndSettle();

      expect(registerCalled, isTrue);
    });

    testWidgets('remove buttons are disabled while submitting', (tester) async {
      final completer = Completer<BulkRegisterResult>();

      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34)],
            entryFee: '10',
            onRegister: (_, __) => completer.future,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Register 2'));
      await tester.pump();

      final chips = tester.widgetList<RemovableCartelaNumberChip>(
        find.byType(RemovableCartelaNumberChip),
      );
      expect(chips.every((chip) => chip.enabled == false), isTrue);

      completer.complete(const BulkRegisterResult(successes: [], failures: []));
      await tester.pumpAndSettle();
    });

    testWidgets('shows bulk progress while submitting', (tester) async {
      final completer = Completer<BulkRegisterResult>();

      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34), _cartela(56)],
            entryFee: '10',
            onRegister: (_, __) => completer.future,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Register 3'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('0 of 3'), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);

      completer.complete(const BulkRegisterResult(successes: [], failures: []));
      await tester.pumpAndSettle();
    });

    testWidgets('bonus review shows free registration copy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34)],
            entryFee: '0',
            isBonus: true,
            fixedPrizeAmount: '5000.00',
            maxCartelasPerPlayer: 5,
            onRegister: (_, __) async =>
                const BulkRegisterResult(successes: [], failures: []),
          ),
        ),
      );

      expect(find.text('2 free cartelas selected'), findsOneWidget);
      expect(find.textContaining('Free entry'), findsOneWidget);
      expect(find.textContaining('Fixed prize'), findsOneWidget);
      expect(find.textContaining('Max 5 cartelas'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Register Free 2'),
        findsOneWidget,
      );
    });

    testWidgets('big gotd review shows paid fixed-prize copy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BulkCartelaReviewSheet(
            selectedCartelas: [_cartela(12), _cartela(34)],
            entryFee: '25.00',
            isBigGotd: true,
            fixedPrizeAmount: '5000.00',
            maxCartelasPerPlayer: 5,
            onRegister: (_, __) async =>
                const BulkRegisterResult(successes: [], failures: []),
          ),
        ),
      );

      expect(find.textContaining('Big GOTD'), findsOneWidget);
      expect(find.textContaining('Entry Fee 25.00'), findsOneWidget);
      expect(find.textContaining('Fixed prize'), findsOneWidget);
      expect(find.textContaining('Max 5 cartelas'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Register 2'), findsOneWidget);
      expect(find.text('Register Free 2'), findsNothing);
    });
  });
}
