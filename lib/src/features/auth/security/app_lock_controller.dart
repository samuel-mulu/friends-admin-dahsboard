import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_manager.dart';
import 'biometric_auth_service.dart';
import '../../../core/storage/secure_token_storage.dart';
import 'local_security_storage.dart';

@immutable
class AppLockState {
  const AppLockState({
    this.isInitializing = false,
    this.isLocked = false,
    this.hasPin = false,
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
    this.failedPinAttempts = 0,
    this.shouldPromptForPinSetup = false,
  });

  final bool isInitializing;
  final bool isLocked;
  final bool hasPin;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final int failedPinAttempts;
  final bool shouldPromptForPinSetup;

  bool get canUseBiometric => isBiometricAvailable && isBiometricEnabled;

  AppLockState copyWith({
    bool? isInitializing,
    bool? isLocked,
    bool? hasPin,
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
    int? failedPinAttempts,
    bool? shouldPromptForPinSetup,
  }) {
    return AppLockState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      shouldPromptForPinSetup:
          shouldPromptForPinSetup ?? this.shouldPromptForPinSetup,
    );
  }
}

final appLockTimeoutProvider = Provider<Duration>((ref) {
  return const Duration(minutes: 60);
});

class AppLockController extends Notifier<AppLockState> {
  late final LocalSecurityStorage _securityStorage;
  late final BiometricAuthService _biometricAuthService;
  late final SecureTokenStorage _tokenStorage;

  DateTime? _inactiveSince;

  @override
  AppLockState build() {
    _securityStorage = ref.read(localSecurityStorageProvider);
    _biometricAuthService = ref.read(biometricAuthServiceProvider);
    _tokenStorage = ref.read(secureTokenStorageProvider);

    ref.listen<SessionState>(sessionManagerProvider, _onSessionChanged);
    unawaited(_loadState());

    return const AppLockState(isInitializing: true);
  }

  Future<void> _loadState() async {
    final pinHash = await _securityStorage.readPinHash();
    final isBiometricAvailable = await _biometricAuthService
        .isBiometricAvailable();
    final isBiometricEnabled = isBiometricAvailable
        ? await _securityStorage.readBiometricEnabled()
        : false;
    final failedPinAttempts = pinHash == null
        ? 0
        : await _securityStorage.readFailedPinAttempts();

    if (!ref.mounted) {
      return;
    }

    state = AppLockState(
      hasPin: pinHash != null && pinHash.isNotEmpty,
      isBiometricAvailable: isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled,
      failedPinAttempts: failedPinAttempts,
    );

    final session = ref.read(sessionManagerProvider).session;
    if (session != null) {
      await _maybePromptAfterAuthentication();
    }
  }

  Future<void> setPin(String pin) async {
    final deviceId = await _tokenStorage.ensureDeviceId();
    final hash = sha256.convert(utf8.encode('$deviceId:$pin')).toString();
    await _securityStorage.savePinHash(hash);
    await _securityStorage.saveFailedPinAttempts(0);
    await _securityStorage.savePinPromptHandled(true);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      hasPin: true,
      failedPinAttempts: 0,
      shouldPromptForPinSetup: false,
      isLocked: false,
    );
  }

  Future<void> clearPin() async {
    await _securityStorage.clearPinHash();
    await _securityStorage.saveBiometricEnabled(false);
    await _securityStorage.saveFailedPinAttempts(0);
    await _securityStorage.savePinPromptHandled(true);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      hasPin: false,
      isBiometricEnabled: false,
      failedPinAttempts: 0,
      shouldPromptForPinSetup: false,
      isLocked: false,
    );
  }

  Future<void> skipPinSetup() async {
    await _securityStorage.savePinPromptHandled(true);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(shouldPromptForPinSetup: false);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final nextEnabled = enabled && state.isBiometricAvailable;
    await _securityStorage.saveBiometricEnabled(nextEnabled);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(isBiometricEnabled: nextEnabled);
  }

  Future<bool> unlockWithBiometric() async {
    if (!state.canUseBiometric) {
      return false;
    }

    final isAuthenticated = await _biometricAuthService.authenticate();
    if (!isAuthenticated || !ref.mounted) {
      return false;
    }

    await _securityStorage.saveFailedPinAttempts(0);
    state = state.copyWith(isLocked: false, failedPinAttempts: 0);
    return true;
  }

  Future<bool> unlockWithPin(String pin) async {
    final storedHash = await _securityStorage.readPinHash();
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    final deviceId = await _tokenStorage.ensureDeviceId();
    final inputHash = sha256.convert(utf8.encode('$deviceId:$pin')).toString();
    if (inputHash == storedHash) {
      await _securityStorage.saveFailedPinAttempts(0);
      if (!ref.mounted) {
        return true;
      }

      state = state.copyWith(isLocked: false, failedPinAttempts: 0);
      return true;
    }

    final nextAttempts = state.failedPinAttempts + 1;
    await _securityStorage.saveFailedPinAttempts(nextAttempts);
    if (nextAttempts >= 5) {
      await ref.read(sessionManagerProvider.notifier).clearLocalSession();
      if (!ref.mounted) {
        return false;
      }

      state = state.copyWith(isLocked: false, failedPinAttempts: nextAttempts);
      return false;
    }

    if (!ref.mounted) {
      return false;
    }

    state = state.copyWith(failedPinAttempts: nextAttempts);
    return false;
  }

  void lock() {
    if (ref.read(sessionManagerProvider).session == null ||
        !state.hasPin ||
        !ref.mounted) {
      return;
    }

    state = state.copyWith(isLocked: true);
  }

  void unlock() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(isLocked: false);
  }

  Future<void> resetFailedPinAttempts() async {
    await _securityStorage.saveFailedPinAttempts(0);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(failedPinAttempts: 0);
  }

  void onAppPaused([DateTime? at]) {
    _inactiveSince = at ?? DateTime.now();
  }

  void onAppResumed([DateTime? at]) {
    final inactiveSince = _inactiveSince;
    _inactiveSince = null;
    if (inactiveSince == null) {
      return;
    }

    final now = at ?? DateTime.now();
    final threshold = ref.read(appLockTimeoutProvider);
    final wasInactiveLongEnough = now.difference(inactiveSince) >= threshold;
    if (wasInactiveLongEnough) {
      lock();
    }
  }

  Future<void> _maybePromptAfterAuthentication() async {
    final handled = await _securityStorage.readPinPromptHandled();
    if (handled || !ref.mounted) {
      return;
    }

    state = state.copyWith(shouldPromptForPinSetup: true);
  }

  void _onSessionChanged(SessionState? previous, SessionState next) {
    final wasAuthenticated = previous?.session != null;
    final isAuthenticated = next.session != null;

    if (!isAuthenticated) {
      state = state.copyWith(isLocked: false, shouldPromptForPinSetup: false);
      return;
    }

    if (!wasAuthenticated && isAuthenticated) {
      unawaited(_maybePromptAfterAuthentication());
    }
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
