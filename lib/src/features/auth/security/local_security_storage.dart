import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalSecurityStorage {
  LocalSecurityStorage(this._storage);

  static const _pinHashKey = 'local_pin_hash';
  static const _biometricEnabledKey = 'local_biometric_enabled';
  static const _failedPinAttemptsKey = 'local_failed_pin_attempts';
  static const _pinPromptHandledKey = 'local_pin_prompt_handled';

  final FlutterSecureStorage _storage;

  Future<String?> readPinHash() {
    return _storage.read(key: _pinHashKey);
  }

  Future<void> savePinHash(String hash) {
    return _storage.write(key: _pinHashKey, value: hash);
  }

  Future<void> clearPinHash() {
    return _storage.delete(key: _pinHashKey);
  }

  Future<bool> readBiometricEnabled() async {
    return (await _storage.read(key: _biometricEnabledKey)) == 'true';
  }

  Future<void> saveBiometricEnabled(bool enabled) {
    return _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<int> readFailedPinAttempts() async {
    final raw = await _storage.read(key: _failedPinAttemptsKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> saveFailedPinAttempts(int attempts) {
    return _storage.write(
      key: _failedPinAttemptsKey,
      value: attempts.toString(),
    );
  }

  Future<bool> readPinPromptHandled() async {
    return (await _storage.read(key: _pinPromptHandledKey)) == 'true';
  }

  Future<void> savePinPromptHandled(bool handled) {
    return _storage.write(
      key: _pinPromptHandledKey,
      value: handled ? 'true' : 'false',
    );
  }
}

final localSecurityStorageProvider = Provider<LocalSecurityStorage>((ref) {
  return LocalSecurityStorage(const FlutterSecureStorage());
});
