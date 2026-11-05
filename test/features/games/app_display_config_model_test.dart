import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/app_display_config_model.dart';

void main() {
  test('fromJson reads bigGamePromotionCardEnabled', () {
    final config = AppDisplayConfigModel.fromJson({
      'bigGamePromotionCardEnabled': false,
    });
    expect(config.bigGamePromotionCardEnabled, isFalse);
  });

  test('fromJson defaults promo card to enabled when field missing', () {
    final config = AppDisplayConfigModel.fromJson({});
    expect(config.bigGamePromotionCardEnabled, isTrue);
  });
}
