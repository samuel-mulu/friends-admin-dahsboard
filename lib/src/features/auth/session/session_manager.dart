import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../data/session_repository.dart';
import '../domain/auth_session.dart';

@immutable
class SessionState {
  const SessionState({this.session, this.isInitializing = false});

  final AuthSession? session;
  final bool isInitializing;

  SessionState copyWith({
    AuthSession? session,
    bool? isInitializing,
    bool clearSession = false,
  }) {
    return SessionState(
      session: clearSession ? null : session ?? this.session,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class SessionManager extends Notifier<SessionState> {
  late final SecureTokenStorage _tokenStorage;
  late final SessionRepository _sessionRepository;

  Future<bool>? _inFlightRefresh;

  @override
  SessionState build() {
    _tokenStorage = ref.read(secureTokenStorageProvider);
    _sessionRepository = ref.read(sessionRepositoryProvider);
    Future.microtask(restoreSession);

    return const SessionState(isInitializing: true);
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isInitializing: true);
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearLocalSession();
      return;
    }

    final cachedSession = await _tokenStorage.readCachedSession();
    if (cachedSession != null && ref.mounted) {
      state = SessionState(session: cachedSession, isInitializing: true);
    }

    await refreshSession();
  }

  Future<void> updateSession(AuthSession session) async {
    final deviceId = await _tokenStorage.ensureDeviceId();
    await _tokenStorage.saveSession(
      session: session,
      deviceId: deviceId,
    );
    if (!ref.mounted) {
      return;
    }

    state = SessionState(session: session);
  }

  Future<String> ensureDeviceId() {
    return _tokenStorage.ensureDeviceId();
  }

  Future<String?> readAccessToken() async {
    final inMemory = state.session?.accessToken;
    if (inMemory != null && inMemory.isNotEmpty) {
      return inMemory;
    }

    return _tokenStorage.readAccessToken();
  }

  Future<bool> refreshSession() {
    final inFlightRefresh = _inFlightRefresh;
    if (inFlightRefresh != null) {
      return inFlightRefresh;
    }

    final completer = Completer<bool>();
    _inFlightRefresh = completer.future;
    () async {
      try {
        final refreshToken = await _tokenStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await clearLocalSession();
          completer.complete(false);
          return;
        }

        final deviceId = await _tokenStorage.ensureDeviceId();
        final session = await _sessionRepository.refresh(
          refreshToken: refreshToken,
          deviceId: deviceId,
        );
        await _tokenStorage.saveSession(
          session: session,
          deviceId: deviceId,
        );
        if (ref.mounted) {
          state = SessionState(session: session);
        }
        completer.complete(true);
      } on ApiException catch (error) {
        _log('refresh failed: ${error.message}');
        if (_shouldClearSessionForRefreshError(error)) {
          await clearLocalSession();
        } else if (ref.mounted) {
          state = SessionState(session: state.session);
        }
        completer.complete(false);
      } catch (error) {
        _log('refresh failed: $error');
        if (ref.mounted) {
          state = SessionState(session: state.session);
        }
        completer.complete(false);
      } finally {
        _inFlightRefresh = null;
      }
    }();

    return completer.future;
  }

  Future<void> logoutCurrentDevice() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    final accessToken = await _tokenStorage.readAccessToken();
    final deviceId = await _tokenStorage.ensureDeviceId();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _sessionRepository.logout(
          refreshToken: refreshToken,
          deviceId: deviceId,
          accessToken: accessToken,
        );
      } catch (error) {
        _log('logout request failed: $error');
      }
    }

    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _tokenStorage.clearSession();
    if (!ref.mounted) {
      return;
    }

    state = const SessionState();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Session] $message');
    }
  }

  bool _shouldClearSessionForRefreshError(ApiException error) {
    final statusCode = error.statusCode;
    return statusCode == 401 || statusCode == 403;
  }
}

final sessionManagerProvider = NotifierProvider<SessionManager, SessionState>(
  SessionManager.new,
);
