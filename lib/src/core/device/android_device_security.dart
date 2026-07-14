import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _deviceSecurityChannel = MethodChannel('friends.com/device_security');

/// Release Android builds only — debug/web/other platforms skip checks.
bool get shouldRunAndroidDeviceSecurityCheck =>
    !kIsWeb && !kDebugMode && defaultTargetPlatform == TargetPlatform.android;

final androidDeviceSecurityProvider = Provider<AndroidDeviceSecurity>(
  (ref) => const AndroidDeviceSecurity(),
);

class AndroidDeviceSecurity {
  const AndroidDeviceSecurity();

  Future<bool> isDeveloperModeEnabled() async {
    if (!shouldRunAndroidDeviceSecurityCheck) {
      return false;
    }

    try {
      final result = await _deviceSecurityChannel.invokeMethod<bool>(
        'isDeveloperModeEnabled',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openDeveloperSettings() async {
    if (!shouldRunAndroidDeviceSecurityCheck) {
      return false;
    }

    try {
      final result = await _deviceSecurityChannel.invokeMethod<bool>(
        'openDeveloperSettings',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
