import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/widgets/auth_validators.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/widgets/otp_resend_button.dart';

void main() {
  group('maskPhoneNumber', () {
    test('masks Ethiopian local numbers as 0962******', () {
      expect(maskPhoneNumber('0962520885'), '0962******');
    });

    test('keeps short numbers unchanged', () {
      expect(maskPhoneNumber('0962'), '0962');
    });
  });

  group('OtpResendButton', () {
    testWidgets('starts disabled with countdown label', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OtpResendButton(
              cooldownSeconds: 180,
              isSending: false,
              onPressed: () async {
                pressed += 1;
              },
            ),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
      expect(find.textContaining('3'), findsOneWidget);
      expect(pressed, 0);
    });

    testWidgets('enables after cooldown and calls onPressed', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OtpResendButton(
              cooldownSeconds: 1,
              isSending: false,
              onPressed: () async {
                pressed += 1;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(pressed, 1);
    });
  });
}
