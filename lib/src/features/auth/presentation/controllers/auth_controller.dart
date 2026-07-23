import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/notifications/firebase_notification_service.dart';
import '../../../../core/notifications/notification_token_repository.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_session.dart';
import '../../session/session_manager.dart';
import '../providers/auth_flow_provider.dart';

class AuthState {
  const AuthState({
    this.session,
    this.isInitializing = false,
    this.isSubmitting = false,
    this.isSendingOtp = false,
    this.errorMessage,
    this.pendingWelcomeBonusCartelasAwarded = 0,
    this.pendingWelcomeBonusDeniedReason,
  });

  final AuthSession? session;
  final bool isInitializing;
  final bool isSubmitting;
  final bool isSendingOtp;
  final String? errorMessage;
  final int pendingWelcomeBonusCartelasAwarded;
  final String? pendingWelcomeBonusDeniedReason;

  AuthState copyWith({
    AuthSession? session,
    bool? isInitializing,
    bool? isSubmitting,
    bool? isSendingOtp,
    String? errorMessage,
    int? pendingWelcomeBonusCartelasAwarded,
    String? pendingWelcomeBonusDeniedReason,
    bool clearErrorMessage = false,
    bool clearPendingWelcomeBonusCartelasAwarded = false,
    bool clearPendingWelcomeBonusDeniedReason = false,
    bool clearSession = false,
  }) {
    return AuthState(
      session: clearSession ? null : session ?? this.session,
      isInitializing: isInitializing ?? this.isInitializing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSendingOtp: isSendingOtp ?? this.isSendingOtp,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      pendingWelcomeBonusCartelasAwarded:
          clearPendingWelcomeBonusCartelasAwarded
          ? 0
          : pendingWelcomeBonusCartelasAwarded ??
                this.pendingWelcomeBonusCartelasAwarded,
      pendingWelcomeBonusDeniedReason: clearPendingWelcomeBonusDeniedReason
          ? null
          : pendingWelcomeBonusDeniedReason ??
                this.pendingWelcomeBonusDeniedReason,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  late final NotificationTokenRepository _notificationTokenRepository;
  late final FirebaseNotificationService _notificationService;
  late final SessionManager _sessionManager;
  late final SocketService _socketService;

  @override
  AuthState build() {
    _authRepository = ref.read(authRepositoryProvider);
    _notificationTokenRepository = ref.read(
      notificationTokenRepositoryProvider,
    );
    _notificationService = ref.read(firebaseNotificationServiceProvider);
    _sessionManager = ref.read(sessionManagerProvider.notifier);
    _socketService = ref.read(socketServiceProvider);

    ref.listen<SessionState>(sessionManagerProvider, _syncWithSessionState);

    final sessionState = ref.read(sessionManagerProvider);
    if (!sessionState.isInitializing) {
      unawaited(_syncSocket(null, sessionState.session));
    }

    return AuthState(
      session: sessionState.session,
      isInitializing: sessionState.isInitializing,
    );
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    _log('login start phone=${AppLogger.maskPhone(phoneNumber)}');
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final deviceId = await _sessionManager.ensureDeviceId();
      final session = await _authRepository.login(
        phoneNumber: phoneNumber,
        password: password,
        deviceId: deviceId,
      );
      await _completeAuthentication(session, clearRegistrationDraft: false);
      _log('login success');
    } catch (error) {
      _log('login failed: $error');
      if (!ref.mounted) {
        return;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<bool> reauthenticateWithPassword(String password) async {
    final session = state.session;
    if (session == null) {
      return false;
    }

    try {
      final deviceId = await _sessionManager.ensureDeviceId();
      final nextSession = await _authRepository.login(
        phoneNumber: session.user.phoneNumber,
        password: password,
        deviceId: deviceId,
      );
      await _sessionManager.updateSession(nextSession);
      return true;
    } catch (error) {
      _log('reauthentication failed: $error');
      return false;
    }
  }

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String otp,
  }) async {
    _log('register start phone=${AppLogger.maskPhone(phoneNumber)}');
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final deviceId = await _sessionManager.ensureDeviceId();
      final session = await _authRepository.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        otp: otp,
        deviceId: deviceId,
      );
      await _completeAuthentication(session, clearRegistrationDraft: true);
      _log('register success');
    } catch (error) {
      _log('register failed: $error');
      if (!ref.mounted) {
        return;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<String?> requestRegisterOtp({required String phoneNumber}) async {
    _log('requestRegisterOtp start phone=${AppLogger.maskPhone(phoneNumber)}');
    state = state.copyWith(isSendingOtp: true, clearErrorMessage: true);

    try {
      final message = await _authRepository.requestRegisterOtp(
        phoneNumber: phoneNumber,
      );
      if (!ref.mounted) {
        return null;
      }

      state = state.copyWith(isSendingOtp: false, clearErrorMessage: true);
      _log('requestRegisterOtp success');
      return message;
    } catch (error) {
      _log('requestRegisterOtp failed: $error');
      if (!ref.mounted) {
        return null;
      }

      state = state.copyWith(
        isSendingOtp: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<String?> requestPasswordResetOtp({required String phoneNumber}) async {
    _log(
      'requestPasswordResetOtp start phone=${AppLogger.maskPhone(phoneNumber)}',
    );
    state = state.copyWith(isSendingOtp: true, clearErrorMessage: true);

    try {
      final message = await _authRepository.requestPasswordResetOtp(
        phoneNumber: phoneNumber,
      );
      if (!ref.mounted) {
        return null;
      }

      state = state.copyWith(isSendingOtp: false, clearErrorMessage: true);
      _log('requestPasswordResetOtp success');
      return message;
    } catch (error) {
      _log('requestPasswordResetOtp failed: $error');
      if (!ref.mounted) {
        return null;
      }

      state = state.copyWith(
        isSendingOtp: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<String?> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    _log('resetPassword start phone=${AppLogger.maskPhone(phoneNumber)}');
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final message = await _authRepository.resetPassword(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
      );
      if (!ref.mounted) {
        return null;
      }

      state = state.copyWith(isSubmitting: false, clearErrorMessage: true);
      _log('resetPassword success');
      return message;
    } catch (error) {
      _log('resetPassword failed: $error');
      if (!ref.mounted) {
        return null;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<void> logout() async {
    _log('logout start');
    await _unregisterNotificationDevice();
    await _notificationService.stopTokenRefreshListener();
    await _sessionManager.logoutCurrentDevice();
    _log('logout complete');
  }

  void clearError() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(clearErrorMessage: true);
  }

  void clearPendingWelcomeBonusCartelasAwarded() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(clearPendingWelcomeBonusCartelasAwarded: true);
  }

  void clearPendingWelcomeBonusDeniedReason() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(clearPendingWelcomeBonusDeniedReason: true);
  }

  Future<void> _completeAuthentication(
    AuthSession session, {
    required bool clearRegistrationDraft,
  }) async {
    await _sessionManager.updateSession(session);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(isSubmitting: false, clearErrorMessage: true);
    if (session.welcomeBonusCartelasAwarded > 0) {
      state = state.copyWith(
        pendingWelcomeBonusCartelasAwarded: session.welcomeBonusCartelasAwarded,
        clearPendingWelcomeBonusDeniedReason: true,
      );
    } else if (session.shouldShowWelcomeBonusDenied) {
      state = state.copyWith(
        pendingWelcomeBonusDeniedReason: session.welcomeBonusDeniedReason,
        clearPendingWelcomeBonusCartelasAwarded: true,
      );
    }

    if (clearRegistrationDraft) {
      ref.read(registrationDraftProvider.notifier).clear();
      ref.read(registerStepProvider.notifier).showDetails();
    }
  }

  void _syncWithSessionState(SessionState? previous, SessionState next) {
    unawaited(_syncSocket(previous?.session, next.session));

    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      session: next.session,
      isInitializing: next.isInitializing,
      isSubmitting: false,
      clearPendingWelcomeBonusCartelasAwarded: next.session == null,
      clearPendingWelcomeBonusDeniedReason: next.session == null,
      clearSession: next.session == null,
    );
  }

  Future<void> _syncSocket(AuthSession? previous, AuthSession? next) async {
    final previousToken = previous?.accessToken;
    final nextToken = next?.accessToken;
    if (previousToken == nextToken) {
      return;
    }

    final deviceId = await _sessionManager.ensureDeviceId();
    _socketService.disconnect();
    if (nextToken == null || nextToken.isEmpty) {
      _socketService.connectAsGuest(deviceId: deviceId);
      return;
    }

    _socketService.connect(nextToken, deviceId: deviceId);
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  void _log(String message) {
    if (kDebugMode) {
      AppLogger.debug('Auth', message);
    }
  }

  Future<void> _unregisterNotificationDevice() async {
    final token = _notificationService.currentToken;
    if (token == null || token.isEmpty) {
      _log('notification unregister skipped: no token');
      return;
    }

    try {
      _log('notification unregister start');
      await _notificationTokenRepository.unregisterDeviceToken(token: token);
      _log('notification unregister success');
    } catch (error) {
      _log('notification unregister failed: $error');
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
