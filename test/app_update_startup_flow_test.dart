import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/app.dart';
import 'package:friends_bingo_app/src/core/config/app_config.dart';
import 'package:friends_bingo_app/src/core/device/screen_awake_service.dart';
import 'package:friends_bingo_app/src/core/notifications/app_push_message.dart';
import 'package:friends_bingo_app/src/core/notifications/firebase_notification_service.dart';
import 'package:friends_bingo_app/src/core/realtime/socket_service.dart';
import 'package:friends_bingo_app/src/core/routing/app_router.dart';
import 'package:friends_bingo_app/src/core/version/android_app_version_model.dart';
import 'package:friends_bingo_app/src/core/version/app_version_info.dart';
import 'package:friends_bingo_app/src/core/version/version_check_controller.dart';
import 'package:friends_bingo_app/src/core/version/version_check_state.dart';
import 'package:friends_bingo_app/src/core/version/version_repository.dart';
import 'package:friends_bingo_app/src/core/version/version_update_resume_recheck.dart';
import 'package:friends_bingo_app/src/core/version/version_update_cache.dart';
import 'package:friends_bingo_app/src/features/auth/security/biometric_auth_service.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/widgets/drawer_app_version_card.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _forcedUpdate = AndroidAppVersionModel(
  version: '2.4.1',
  versionCode: 5,
  minimumVersionCode: 3,
  downloadUrl: 'https://example.com/app-release.apk',
  sha256: 'abc123',
  releaseNotes: 'Critical fixes',
  forceUpdate: true,
);

const _optionalUpdate = AndroidAppVersionModel(
  version: '2.4.1',
  versionCode: 5,
  minimumVersionCode: 3,
  downloadUrl: 'https://example.com/app-release.apk',
  sha256: 'abc123',
  releaseNotes: 'Stability improvements',
  forceUpdate: false,
);

Future<void> _waitForVersionCheckResult(
  WidgetTester tester,
  ProviderContainer container, {
  VersionCheckKind? expectedKind,
}) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 20));
    final kind = container.read(versionCheckControllerProvider).kind;
    if (expectedKind != null) {
      if (kind == expectedKind) {
        break;
      }
    } else if (kind != VersionCheckKind.none ||
        container.read(versionCheckReadyProvider)) {
      break;
    }
  }
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'local_pin_prompt_handled': 'true',
    });
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'android startup shows forced update gate before leaving loading',
    (tester) async {
      final container = await _pumpApp(tester, remote: _forcedUpdate);

      await _waitForVersionCheckResult(
        tester,
        container,
        expectedKind: VersionCheckKind.force,
      );

      expect(
        container.read(versionCheckControllerProvider).kind,
        VersionCheckKind.force,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Critical fixes'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'forced update gate stays visible after auth would redirect away',
    (tester) async {
      final container = await _pumpApp(tester, remote: _forcedUpdate);

      await _waitForVersionCheckResult(
        tester,
        container,
        expectedKind: VersionCheckKind.force,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Critical fixes'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'android startup reaches home while optional update check runs',
    (tester) async {
      final container = await _pumpApp(tester, remote: _optionalUpdate);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(versionCheckReadyProvider), isTrue);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Update available'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'manual drawer check still shows optional update dialog',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installedAppVersionProvider.overrideWith(
              (ref) async => const InstalledAppVersion(
                version: '1.0.0',
                buildNumber: 4,
              ),
            ),
            installedBuildNumberReaderProvider.overrideWithValue(() async => 4),
            versionRepositoryProvider.overrideWithValue(
              _StubVersionRepository(_optionalUpdate),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DrawerAppVersionCard()),
          ),
        ),
      );

      await tester.tap(find.text('App version'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Stability improvements'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'forced update rechecks after resume while gate stays visible',
    (tester) async {
      final repository = _StubVersionRepository(_forcedUpdate);

      final container = await _pumpApp(
        tester,
        remote: _forcedUpdate,
        repository: repository,
      );

      await _waitForVersionCheckResult(
        tester,
        container,
        expectedKind: VersionCheckKind.force,
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Critical fixes'), findsOneWidget);
      expect(repository.fetchCount, 1);

      container
          .read(versionUpdateResumeRecheckControllerProvider.notifier)
          .markForRecheck();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _waitForVersionCheckResult(
        tester,
        container,
        expectedKind: VersionCheckKind.force,
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Critical fixes'), findsOneWidget);
      expect(repository.fetchCount, 2);

      await tester.pump(const Duration(milliseconds: 500));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required AndroidAppVersionModel remote,
  _StubVersionRepository? repository,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      versionRepositoryProvider.overrideWithValue(
        repository ?? _StubVersionRepository(remote),
      ),
      versionUpdateCacheProvider.overrideWith((ref) async {
        final prefs = await SharedPreferences.getInstance();
        return VersionUpdateCache(prefs);
      }),
      installedBuildNumberReaderProvider.overrideWithValue(() async => 4),
      installedAppVersionProvider.overrideWith(
        (ref) async => const InstalledAppVersion(
          version: '1.0.0',
          buildNumber: 4,
        ),
      ),
      screenAwakeServiceProvider.overrideWithValue(_FakeScreenAwakeService()),
      biometricAuthServiceProvider.overrideWithValue(
        _FakeBiometricAuthService(),
      ),
      socketServiceProvider.overrideWithValue(_FakeSocketService()),
      firebaseNotificationServiceProvider.overrideWithValue(
        _FakeFirebaseNotificationService(),
      ),
    ],
  );

  addTearDown(() {
    router.dispose();
    container.dispose();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FriendsBingoApp(),
    ),
  );

  return container;
}

class _StubVersionRepository implements VersionRepository {
  _StubVersionRepository(this._response);

  final AndroidAppVersionModel _response;
  int fetchCount = 0;

  @override
  Future<AndroidAppVersionModel> fetchAndroidVersion() async {
    fetchCount += 1;
    return _response;
  }
}

class _FakeBiometricAuthService extends BiometricAuthService {
  _FakeBiometricAuthService() : super(LocalAuthentication());

  @override
  Future<bool> isBiometricAvailable() async => false;
}

class _FakeSocketService extends SocketService {
  _FakeSocketService()
    : super(
        AppConfig(
          apiBaseUrl: 'http://localhost:3002',
          socketBaseUrl: 'http://localhost:3002',
        ),
      );

  @override
  void connect(String token) {}

  @override
  void connectAsGuest() {}

  @override
  void disconnect() {}
}

class _FakeScreenAwakeService implements ScreenAwakeService {
  @override
  Future<void> setEnabled(bool enabled) async {}
}

class _FakeFirebaseNotificationService extends FirebaseNotificationService {
  @override
  Stream<AppPushMessage> get notificationTapStream =>
      const Stream<AppPushMessage>.empty();
}
