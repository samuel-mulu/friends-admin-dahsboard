import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/config/app_support.dart';

void main() {
  group('AppSupportConfig', () {
    test('fromJson maps API fields and strips telegram @', () {
      final config = AppSupportConfig.fromJson({
        'phoneNumber1': '0911000000',
        'phoneNumber2': '0922000000',
        'telegramUsername': '@friendsbingo',
        'termsBody': 'Updated terms',
      });

      expect(config.phoneNumber1, '0911000000');
      expect(config.phoneNumber2, '0922000000');
      expect(config.telegramUsername, 'friendsbingo');
      expect(config.termsBody, 'Updated terms');
      expect(config.supportPhoneDisplays, ['0911000000', '0922000000']);
      expect(config.supportPhoneDisplay, '0911000000 / 0922000000');
      expect(config.telegramUri.toString(), 'https://t.me/friendsbingo');
    });

    test('omits blank secondary phone from display list', () {
      final config = AppSupportConfig.fromJson({
        'phoneNumber1': '0911000000',
        'phoneNumber2': '  ',
        'telegramUsername': 'friendsbingo',
        'termsBody': 'Terms',
      });

      expect(config.supportPhoneDisplays, ['0911000000']);
    });

    test('toTelUri converts local Ethiopian numbers', () {
      expect(AppSupportConfig.toTelUri('0961355799'), 'tel:+251961355799');
      expect(AppSupportConfig.toTelUri('0983299318'), 'tel:+251983299318');
      expect(AppSupportConfig.toTelUri('+251961355799'), 'tel:+251961355799');
    });
  });
}
