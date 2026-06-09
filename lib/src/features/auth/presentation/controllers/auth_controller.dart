import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_session.dart';
import '../providers/auth_flow_provider.dart';

class AuthState {
  const AuthState({
    this.session,
    this.isInitializing = false,
    this.isSubmitting = false,
    this.isSendingOtp = false,
    this.errorMessage,
  });

  final AuthSession? session;
  final bool isInitializing;
  final bool isSubmitting;
  final bool isSendingOtp;
  final String? errorMessage;

  AuthState copyWith({
    AuthSession? session,
    bool? isInitializing,
    bool? isSubmitting,
    bool? isSendingOtp,
    String? errorMessage,
    bool clearErrorMessage = false,
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
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  late final SecureTokenStorage _tokenStorage;
  late final SocketService _socketService;

  @override
  AuthState build() {
    _authRepository = ref.read(authRepositoryProvider);
    _tokenStorage = ref.read(secureTokenStorageProvider);
    _socketService = ref.read(socketServiceProvider);
    unawaited(_restoreSession());

    return const AuthState(isInitializing: true);
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    _log('login start phone=$phoneNumber');
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final session = await _authRepository.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      await _completeAuthentication(
        session,
        clearRegistrationDraft: false,
      );
      _log('login success user=${session.user.id}');
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

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String otp,
  }) async {
    _log('register start phone=$phoneNumber');
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final session = await _authRepository.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        otp: otp,
      );
      await _completeAuthentication(
        session,
        clearRegistrationDraft: true,
      );
      _log('register success user=${session.user.id}');
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
    _log('requestRegisterOtp start phone=$phoneNumber');
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
    _log('requestPasswordResetOtp start phone=$phoneNumber');
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
    _log('resetPassword start phone=$phoneNumber');
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
    await _tokenStorage.clear();
    _socketService.disconnect();
    _socketService.connectAsGuest();
    if (!ref.mounted) {
      return;
    }

    state = const AuthState();
  }

  void clearError() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(clearErrorMessage: true);
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (!ref.mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      _socketService.connectAsGuest();
      state = const AuthState();
      return;
    }

    try {
      final user = await _authRepository.getCurrentUser();
      if (!ref.mounted) {
        return;
      }

      final session = AuthSession(accessToken: token, user: user);
      _socketService.connect(token);
      state = AuthState(session: session);
    } catch (_) {
      await _tokenStorage.clear();
      _socketService.disconnect();
      _socketService.connectAsGuest();
      if (!ref.mounted) {
        return;
      }

      state = const AuthState();
    }
  }

  Future<void> _completeAuthentication(
    AuthSession session, {
    required bool clearRegistrationDraft,
  }) async {
    await _tokenStorage.saveAccessToken(session.accessToken);
    if (!ref.mounted) {
      return;
    }

    state = AuthState(session: session);

    Future.microtask(() {
      if (!ref.mounted) {
        return;
      }

      _socketService.connect(session.accessToken);

      if (clearRegistrationDraft) {
        ref.read(registrationDraftProvider.notifier).clear();
        ref.read(registerStepProvider.notifier).showDetails();
      }
    });
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Auth] $message');
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
