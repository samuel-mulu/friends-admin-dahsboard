import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/app.dart';
import 'package:friends_bingo_app/src/core/config/app_config.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/core/notifications/auth_notification_sync.dart';
import 'package:friends_bingo_app/src/core/notifications/firebase_notification_service.dart';
import 'package:friends_bingo_app/src/core/notifications/notification_token_repository.dart';
import 'package:friends_bingo_app/src/core/realtime/socket_service.dart';
import 'package:friends_bingo_app/src/core/routing/app_router.dart';
import 'package:friends_bingo_app/src/core/storage/secure_token_storage.dart';
import 'package:friends_bingo_app/src/features/auth/data/auth_repository.dart';
import 'package:friends_bingo_app/src/features/auth/data/session_repository.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/widgets/pin_setup_dialog.dart';
import 'package:friends_bingo_app/src/features/auth/security/app_lock_controller.dart';
import 'package:friends_bingo_app/src/features/auth/security/biometric_auth_service.dart';
import 'package:friends_bingo_app/src/features/auth/session/session_manager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository authRepository;
  late FakeSessionRepository sessionRepository;
  late FakeBiometricAuthService biometricAuthService;
  late FakeFirebaseNotificationService firebaseNotificationService;
  late FakeNotificationTokenRepository notificationTokenRepository;
  late FakeSocketService socketService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'local_pin_prompt_handled': 'true',
    });
    SharedPreferences.setMockInitialValues(<String, Object>{});
    authRepository = FakeAuthRepository();
    sessionRepository = FakeSessionRepository();
    biometricAuthService = FakeBiometricAuthService();
    firebaseNotificationService = FakeFirebaseNotificationService();
    notificationTokenRepository = FakeNotificationTokenRepository();
    socketService = FakeSocketService();
  });

  test('login stores access and refresh tokens securely', () async {
    authRepository.loginSession = _session(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );

    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _settleAsync();
    await container
        .read(authControllerProvider.notifier)
        .login(phoneNumber: '0912345678', password: 'pw');

    final storage = container.read(secureTokenStorageProvider);
    expect(await storage.readAccessToken(), 'access-1');
    expect(await storage.readRefreshToken(), 'refresh-1');
    expect(await storage.ensureDeviceId(), isNotEmpty);
  });

  test('legacy login without refresh token does not persist a refresh session', () async {
    authRepository.loginSession = AuthSession(
      accessToken: 'access-legacy',
      user: _user(),
    );

    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _settleAsync();
    await container
        .read(authControllerProvider.notifier)
        .login(phoneNumber: '0912345678', password: 'pw');

    final storage = container.read(secureTokenStorageProvider);
    expect(await storage.readAccessToken(), 'access-legacy');
    expect(await storage.readRefreshToken(), isNull);
  });

  test('app restart refreshes session from stored refresh token', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'refresh_token': 'refresh-old',
      'device_id': 'device-1',
    });
    sessionRepository.refreshResults.add(
      _session(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );

    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _settleAsync();

    expect(
      container.read(authControllerProvider).session?.accessToken,
      'access-2',
    );
    expect(
      container.read(authControllerProvider).session?.refreshToken,
      'refresh-2',
    );
    expect(sessionRepository.refreshTokensSeen, ['refresh-old']);
  });

  test('refresh rotation updates the stored refresh token each time', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'refresh_token': 'refresh-old',
      'device_id': 'device-1',
    });
    sessionRepository.refreshResults.addAll([
      _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
      _session(accessToken: 'access-2', refreshToken: 'refresh-2'),
    ]);

    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(sessionManagerProvider);
    await _settleAsync();
    await container.read(sessionManagerProvider.notifier).refreshSession();

    final storage = container.read(secureTokenStorageProvider);
    expect(sessionRepository.refreshTokensSeen, ['refresh-old', 'refresh-1']);
    expect(await storage.readRefreshToken(), 'refresh-2');
  });

  test(
    'logout revokes the current refresh session and clears storage',
    () async {
      final container = _createContainer(
        authRepository: authRepository,
        sessionRepository: sessionRepository,
        biometricAuthService: biometricAuthService,
        firebaseNotificationService: firebaseNotificationService,
        notificationTokenRepository: notificationTokenRepository,
        socketService: socketService,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _settleAsync();
      await container
          .read(sessionManagerProvider.notifier)
          .updateSession(
            _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
          );
      firebaseNotificationService.currentTokenValue = 'fcm-token-1';

      await container.read(authControllerProvider.notifier).logout();

      final storage = container.read(secureTokenStorageProvider);
      expect(notificationTokenRepository.unregisterCalls, ['fcm-token-1']);
      expect(sessionRepository.logoutCalls, 1);
      expect(sessionRepository.lastLogoutRefreshToken, 'refresh-1');
      expect(sessionRepository.lastLogoutDeviceId, isNotEmpty);
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    },
  );

  test('logout clears auth tokens but preserves the device identity', () async {
    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    final storage = container.read(secureTokenStorageProvider);
    final originalDeviceId = await storage.ensureDeviceId();
    await container.read(sessionManagerProvider.notifier).updateSession(
          _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
        );

    await container.read(authControllerProvider.notifier).logout();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await storage.ensureDeviceId(), originalDeviceId);
  });

  test('login triggers token registration', () async {
    firebaseNotificationService.permissionGranted = true;
    firebaseNotificationService.currentTokenValue = 'fcm-token-1';
    final sync = AuthNotificationSync(
      firebaseNotificationService,
      notificationTokenRepository,
    );

    await sync.syncAuthenticatedSession();

    expect(
      notificationTokenRepository.registerCalls,
      [
        (
          token: 'fcm-token-1',
          platform: 'android',
        ),
      ],
    );
  });

  test('token refresh re-registers', () async {
    firebaseNotificationService.permissionGranted = true;
    firebaseNotificationService.currentTokenValue = 'fcm-token-1';
    final sync = AuthNotificationSync(
      firebaseNotificationService,
      notificationTokenRepository,
    );

    await sync.syncAuthenticatedSession();

    await firebaseNotificationService.emitTokenRefresh('fcm-token-2');

    expect(
      notificationTokenRepository.registerCalls,
      [
        (
          token: 'fcm-token-1',
          platform: 'android',
        ),
        (
          token: 'fcm-token-2',
          platform: 'android',
        ),
      ],
    );
  });

  testWidgets('expired refresh keeps the user on the guest live games route', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'refresh_token': 'expired-refresh',
      'device_id': 'device-1',
    });
    sessionRepository.refreshError = ApiException(message: 'Expired');
    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FriendsBingoApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(appRouterProvider).state.matchedLocation, '/games');
  });

  test('PIN unlock works for a stored 4-digit PIN', () async {
    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(appLockControllerProvider);
    await _settleAsync();
    await container
        .read(sessionManagerProvider.notifier)
        .updateSession(
          _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
        );
    await container.read(appLockControllerProvider.notifier).setPin('1234');
    container.read(appLockControllerProvider.notifier).lock();

    final unlocked = await container
        .read(appLockControllerProvider.notifier)
        .unlockWithPin('1234');

    expect(unlocked, isTrue);
    expect(container.read(appLockControllerProvider).isLocked, isFalse);
  });

  test('first successful authentication prompts for PIN setup only once', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(appLockControllerProvider);
    container.read(authControllerProvider);
    await _settleAsync();
    await container.read(authControllerProvider.notifier).login(
          phoneNumber: '0912345678',
          password: 'pw',
        );
    await _settleAsync();

    expect(
      container.read(appLockControllerProvider).shouldPromptForPinSetup,
      isTrue,
    );

    await container.read(appLockControllerProvider.notifier).skipPinSetup();
    await container.read(authControllerProvider.notifier).logout();
    await container.read(authControllerProvider.notifier).login(
          phoneNumber: '0912345678',
          password: 'pw',
        );
    await _settleAsync();

    expect(
      container.read(appLockControllerProvider).shouldPromptForPinSetup,
      isFalse,
    );
  });

  test('app stays unlocked when resumed before the 60 minute threshold', () async {
    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(appLockControllerProvider);
    await _settleAsync();
    await container.read(sessionManagerProvider.notifier).updateSession(
          _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
        );
    await container.read(appLockControllerProvider.notifier).setPin('1234');

    final pausedAt = DateTime.utc(2026, 6, 22, 9, 0);
    container.read(appLockControllerProvider.notifier).onAppPaused(pausedAt);
    container
        .read(appLockControllerProvider.notifier)
        .onAppResumed(pausedAt.add(const Duration(minutes: 59, seconds: 59)));

    expect(container.read(appLockControllerProvider).isLocked, isFalse);
  });

  test('app locks after 60 minutes of inactivity when a PIN exists', () async {
    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(appLockControllerProvider);
    await _settleAsync();
    await container.read(sessionManagerProvider.notifier).updateSession(
          _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
        );
    await container.read(appLockControllerProvider.notifier).setPin('1234');

    final pausedAt = DateTime.utc(2026, 6, 22, 9, 0);
    container.read(appLockControllerProvider.notifier).onAppPaused(pausedAt);
    container
        .read(appLockControllerProvider.notifier)
        .onAppResumed(pausedAt.add(const Duration(minutes: 60)));

    expect(container.read(appLockControllerProvider).isLocked, isTrue);
  });

  test('app does not lock after inactivity when no PIN is set', () async {
    final container = _createContainer(
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      biometricAuthService: biometricAuthService,
      firebaseNotificationService: firebaseNotificationService,
      notificationTokenRepository: notificationTokenRepository,
      socketService: socketService,
    );
    addTearDown(container.dispose);

    container.read(appLockControllerProvider);
    await _settleAsync();
    await container.read(sessionManagerProvider.notifier).updateSession(
          _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
        );

    final pausedAt = DateTime.utc(2026, 6, 22, 9, 0);
    container.read(appLockControllerProvider.notifier).onAppPaused(pausedAt);
    container
        .read(appLockControllerProvider.notifier)
        .onAppResumed(pausedAt.add(const Duration(hours: 2)));

    expect(container.read(appLockControllerProvider).isLocked, isFalse);
  });

  test(
    'wrong PIN blocks after 5 attempts by clearing the local session',
    () async {
      final container = _createContainer(
        authRepository: authRepository,
        sessionRepository: sessionRepository,
        biometricAuthService: biometricAuthService,
        firebaseNotificationService: firebaseNotificationService,
        notificationTokenRepository: notificationTokenRepository,
        socketService: socketService,
      );
      addTearDown(container.dispose);

      container.read(appLockControllerProvider);
      await _settleAsync();
      await container
          .read(sessionManagerProvider.notifier)
          .updateSession(
            _session(accessToken: 'access-1', refreshToken: 'refresh-1'),
          );
      await container.read(appLockControllerProvider.notifier).setPin('1234');
      container.read(appLockControllerProvider.notifier).lock();

      for (var i = 0; i < 5; i++) {
        await container
            .read(appLockControllerProvider.notifier)
            .unlockWithPin('9999');
      }

      expect(container.read(authControllerProvider).session, isNull);
    },
  );

  testWidgets('biometric unavailable hides the fingerprint option', (
    tester,
  ) async {
    biometricAuthService.isAvailable = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          sessionRepositoryProvider.overrideWithValue(sessionRepository),
          biometricAuthServiceProvider.overrideWithValue(biometricAuthService),
          firebaseNotificationServiceProvider.overrideWithValue(
            firebaseNotificationService,
          ),
          notificationTokenRepositoryProvider.overrideWithValue(
            notificationTokenRepository,
          ),
          socketServiceProvider.overrideWithValue(socketService),
        ],
        child: const MaterialApp(home: Scaffold(body: PinSetupDialog())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Use fingerprint'), findsNothing);
  });
}

ProviderContainer _createContainer({
  required FakeAuthRepository authRepository,
  required FakeSessionRepository sessionRepository,
  required FakeBiometricAuthService biometricAuthService,
  required FakeFirebaseNotificationService firebaseNotificationService,
  required FakeNotificationTokenRepository notificationTokenRepository,
  required FakeSocketService socketService,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      sessionRepositoryProvider.overrideWithValue(sessionRepository),
      biometricAuthServiceProvider.overrideWithValue(biometricAuthService),
      firebaseNotificationServiceProvider.overrideWithValue(
        firebaseNotificationService,
      ),
      notificationTokenRepositoryProvider.overrideWithValue(
        notificationTokenRepository,
      ),
      socketServiceProvider.overrideWithValue(socketService),
    ],
  );
}

Future<void> _settleAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

AuthSession _session({
  required String accessToken,
  String? refreshToken,
}) {
  return AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: _user(),
  );
}

UserProfile _user() {
  return UserProfile(
    id: 'user-1',
    fullName: 'Test Player',
    phoneNumber: '0912345678',
    role: UserRole.player,
    status: UserStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(ApiClient(Dio()));

  AuthSession? loginSession;

  @override
  Future<AuthSession> login({
    required String phoneNumber,
    required String password,
    required String deviceId,
  }) async {
    return loginSession ??
        _session(
          accessToken: 'fallback-access',
          refreshToken: 'fallback-refresh',
        );
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String otp,
    required String deviceId,
  }) async {
    return login(
      phoneNumber: phoneNumber,
      password: password,
      deviceId: deviceId,
    );
  }
}

class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository() : super(Dio());

  final List<AuthSession> refreshResults = <AuthSession>[];
  final List<String> refreshTokensSeen = <String>[];
  ApiException? refreshError;
  int logoutCalls = 0;
  String? lastLogoutRefreshToken;
  String? lastLogoutDeviceId;

  @override
  Future<AuthSession> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    refreshTokensSeen.add(refreshToken);
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshResults.removeAt(0);
  }

  @override
  Future<void> logout({
    required String refreshToken,
    required String deviceId,
    String? accessToken,
  }) async {
    logoutCalls += 1;
    lastLogoutRefreshToken = refreshToken;
    lastLogoutDeviceId = deviceId;
  }
}

class FakeBiometricAuthService extends BiometricAuthService {
  FakeBiometricAuthService() : super(LocalAuthentication());

  bool isAvailable = false;
  bool authenticateResult = false;

  @override
  Future<bool> isBiometricAvailable() async => isAvailable;

  @override
  Future<bool> authenticate() async => authenticateResult;
}

class FakeFirebaseNotificationService extends FirebaseNotificationService {
  bool permissionGranted = false;
  String? currentTokenValue;
  Future<void> Function(String token)? _refreshHandler;

  @override
  bool get isSupportedPlatform => true;

  @override
  String? get currentToken => currentTokenValue;

  @override
  String get platform => 'android';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<String?> getToken() async => currentTokenValue;

  @override
  Future<void> listenForTokenRefresh(
    Future<void> Function(String token) onTokenRefresh,
  ) async {
    _refreshHandler = onTokenRefresh;
  }

  @override
  Future<void> stopTokenRefreshListener() async {
    _refreshHandler = null;
  }

  Future<void> emitTokenRefresh(String token) async {
    currentTokenValue = token;
    await _refreshHandler?.call(token);
  }
}

class FakeNotificationTokenRepository extends NotificationTokenRepository {
  FakeNotificationTokenRepository() : super(ApiClient(Dio()));

  final List<({String token, String platform})> registerCalls = [];
  final List<String> unregisterCalls = [];

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    registerCalls.add((token: token, platform: platform));
  }

  @override
  Future<void> unregisterDeviceToken({required String token}) async {
    unregisterCalls.add(token);
  }
}

class FakeSocketService extends SocketService {
  FakeSocketService()
    : super(
        AppConfig(
          apiBaseUrl: 'http://localhost:3002',
          socketBaseUrl: 'http://localhost:3002',
        ),
      );

  int connectCalls = 0;
  int connectAsGuestCalls = 0;
  int disconnectCalls = 0;

  @override
  void connect(String token) {
    connectCalls += 1;
  }

  @override
  void connectAsGuest() {
    connectAsGuestCalls += 1;
  }

  @override
  void disconnect() {
    disconnectCalls += 1;
  }
}
