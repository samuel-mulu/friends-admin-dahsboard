import 'package:friends_bingo_app/src/features/wallet/data/models/deposit_config_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelebirrDepositConfig', () {
    test('parses accounts array from backend config', () {
      final config = TelebirrDepositConfig.fromJson({
        'providerName': 'Telebirr',
        'receiptBaseUrl': 'https://transactioninfo.ethiotelecom.et/receipt',
        'receiverPhoneLast4': '1234',
        'receiverName': 'Primary Name',
        'accounts': [
          {
            'settlementAccount': '0911111111',
            'receiverName': 'Primary Name',
            'receiverPhoneLast4': '1111',
          },
          {
            'settlementAccount': '0922222222',
            'receiverName': 'Secondary Name',
            'receiverPhoneLast4': '2222',
          },
        ],
      });

      expect(config.accounts, hasLength(2));
      expect(config.accounts[0].settlementAccount, '0911111111');
      expect(config.accounts[1].settlementAccount, '0922222222');
    });

    test('resolvedAccounts falls back to provider settlement account', () {
      final config = TelebirrDepositConfig.fromJson({
        'providerName': 'Telebirr',
        'receiverPhoneLast4': '1234',
        'receiverName': 'Primary Name',
      });

      final resolved = config.resolvedAccounts(
        fallbackSettlementAccount: '0911111111',
      );

      expect(resolved, hasLength(1));
      expect(resolved.first.settlementAccount, '0911111111');
      expect(resolved.first.receiverName, 'Primary Name');
      expect(resolved.first.receiverPhoneLast4, '1234');
    });

    test('resolvedAccounts prefers accounts array when present', () {
      final config = TelebirrDepositConfig.fromJson({
        'accounts': [
          {
            'settlementAccount': '0911111111',
            'receiverName': 'Primary Name',
            'receiverPhoneLast4': '1111',
          },
          {
            'settlementAccount': '0922222222',
            'receiverName': 'Secondary Name',
            'receiverPhoneLast4': '2222',
          },
        ],
      });

      final resolved = config.resolvedAccounts(
        fallbackSettlementAccount: '0999999999',
      );

      expect(resolved, hasLength(2));
      expect(resolved.first.settlementAccount, '0911111111');
      expect(resolved.last.settlementAccount, '0922222222');
    });
  });
}
