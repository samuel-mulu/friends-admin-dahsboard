import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract class ScreenAwakeService {
  Future<void> setEnabled(bool enabled);
}

class WakelockScreenAwakeService implements ScreenAwakeService {
  const WakelockScreenAwakeService();

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!_supportsKeepAwake) {
      return;
    }

    if (enabled) {
      await WakelockPlus.enable();
      return;
    }

    await WakelockPlus.disable();
  }

  bool get _supportsKeepAwake {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      _ => false,
    };
  }
}

final screenAwakeServiceProvider = Provider<ScreenAwakeService>((ref) {
  return const WakelockScreenAwakeService();
});
