import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_device_security.dart';

class DeviceSecurityState {
  const DeviceSecurityState({
    this.isChecking = false,
    this.isBlocked = false,
  });

  final bool isChecking;
  final bool isBlocked;

  DeviceSecurityState copyWith({
    bool? isChecking,
    bool? isBlocked,
  }) {
    return DeviceSecurityState(
      isChecking: isChecking ?? this.isChecking,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class DeviceSecurityController extends Notifier<DeviceSecurityState> {
  @override
  DeviceSecurityState build() => const DeviceSecurityState();

  Future<void> check() async {
    if (!shouldRunAndroidDeviceSecurityCheck) {
      state = const DeviceSecurityState();
      return;
    }

    state = state.copyWith(isChecking: true);

    final blocked = await ref
        .read(androidDeviceSecurityProvider)
        .isDeveloperModeEnabled();

    if (!ref.mounted) {
      return;
    }

    state = DeviceSecurityState(isBlocked: blocked);
  }
}

final deviceSecurityControllerProvider =
    NotifierProvider<DeviceSecurityController, DeviceSecurityState>(
      DeviceSecurityController.new,
    );
