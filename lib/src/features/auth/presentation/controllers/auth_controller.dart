import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_session.dart';

class AuthState {
  const AuthState({
    this.session,
    this.isInitializing = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthSession? session;
  final bool isInitializing;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthSession? session,
    bool? isInitializing,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      isInitializing: isInitializing ?? this.isInitializing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
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
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final session = await _authRepository.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      await _persistSession(session);
    } catch (error) {
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
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final session = await _authRepository.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        otp: otp,
      );
      await _persistSession(session);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<String?> requestRegisterOtp({required String phoneNumber}) async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final message = await _authRepository.requestRegisterOtp(
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isSubmitting: false, clearErrorMessage: true);
      return message;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<String?> requestPasswordResetOtp({required String phoneNumber}) async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final message = await _authRepository.requestPasswordResetOtp(
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isSubmitting: false, clearErrorMessage: true);
      return message;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
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
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final message = await _authRepository.resetPassword(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(isSubmitting: false, clearErrorMessage: true);
      return message;
    } catch (error) {
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
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }

    try {
      final user = await _authRepository.getCurrentUser();
      final session = AuthSession(accessToken: token, user: user);
      _socketService.connect(token);
      state = AuthState(session: session);
    } catch (_) {
      await _tokenStorage.clear();
      _socketService.disconnect();
      state = const AuthState();
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    await _tokenStorage.saveAccessToken(session.accessToken);
    _socketService.connect(session.accessToken);
    state = AuthState(session: session);
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
