import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService(this._localAuthentication);

  final LocalAuthentication _localAuthentication;

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final isSupported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final available = await _localAuthentication.getAvailableBiometrics();
      return isSupported && canCheck && available.isNotEmpty;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Unlock Friends Bingo',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on MissingPluginException {
      return false;
    }
  }
}

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(LocalAuthentication());
});
