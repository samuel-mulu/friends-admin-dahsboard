import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/utils/wallet_validation_utils.dart';

void main() {
  group('WalletValidationUtils', () {
    test('phonesMatch handles Ethiopian phone numbers across formats', () {
      expect(WalletValidationUtils.phonesMatch('0911223344', '0911223344'), isTrue);
      expect(WalletValidationUtils.phonesMatch('+251911223344', '0911223344'), isTrue);
      expect(WalletValidationUtils.phonesMatch('251911223344', '911223344'), isTrue);
      expect(WalletValidationUtils.phonesMatch('0911223344', '0922334455'), isFalse);
    });

    test('isOtherTelebirrNumber detects when phone is different from own', () {
      expect(
        WalletValidationUtils.isOtherTelebirrNumber(
          provider: PaymentProvider.telebirr,
          ownPhone: '0911223344',
          enteredPhone: '0922334455',
        ),
        isTrue,
      );

      expect(
        WalletValidationUtils.isOtherTelebirrNumber(
          provider: PaymentProvider.telebirr,
          ownPhone: '0911223344',
          enteredPhone: '0911223344',
        ),
        isFalse,
      );

      expect(
        WalletValidationUtils.isOtherTelebirrNumber(
          provider: PaymentProvider.cbe,
          ownPhone: '0911223344',
          enteredPhone: '0922334455',
        ),
        isFalse,
      );
    });
  });
}
