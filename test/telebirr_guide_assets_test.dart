import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/guides/deposit_guide_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('telebirr deposit guide assets decode', () async {
    for (final step in [1, 2, 3]) {
      final path = depositGuideAssetPath(PaymentProvider.telebirr, step);
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0));
      expect(frame.image.height, greaterThan(0));
      frame.image.dispose();
    }
  });
}
