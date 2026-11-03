import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/bulk_register_result.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/bulk_cartela_review_sheet.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  group('Big Game single-cartela hold release & bulk review ticket balance (BUG-07)', () {
    testWidgets(
      'BulkCartelaReviewSheet deducts bigGameTicketBalance when computing total cost for Big Game',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BulkCartelaReviewSheet(
                selectedCartelas: [
                  CartelaModel(id: 'c-1', number: 1, createdAt: now),
                  CartelaModel(id: 'c-2', number: 2, createdAt: now),
                ],
                entryFee: '50',
                isBigGame: true,
                bigGameTicketBalance: 2,
                onRegister: (cartelas, onProgress) async {
                  return const BulkRegisterResult(
                    successes: [],
                    failures: [],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // With 2 Big Game tickets covering 2 selected cartelas at 50 ETB each,
        // the total wallet charge shown must be Free / 0 ETB, not 100.00 ETB.
        expect(find.textContaining('100'), findsNothing);
      },
    );

    test(
      'CartelaRegistrationSheet releases active hold before calling registerCartela for Big Game',
      () {
        final sheetSource = File(
          'lib/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart',
        ).readAsStringSync();

        final startIdx = sheetSource.indexOf('if (_isBigGame) {');
        expect(startIdx, greaterThanOrEqualTo(0));
        final bigGameBranch = sheetSource.substring(startIdx, startIdx + 800);

        expect(
          bigGameBranch.contains(
            '_releaseReservation(applyAvailablePatch: false)',
          ),
          isTrue,
          reason:
              'Big Game registerCartela/registerCartelaForSlot does not consume _reservationId, so the sheet must release its hold before/during registration',
        );
      },
    );
  });
}
