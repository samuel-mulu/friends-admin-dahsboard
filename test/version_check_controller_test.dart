import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/version/android_app_version_model.dart';
import 'package:friends_bingo_app/src/core/version/app_version_info.dart';
import 'package:friends_bingo_app/src/core/version/version_check_controller.dart';
import 'package:friends_bingo_app/src/core/version/version_check_state.dart';
import 'package:friends_bingo_app/src/core/version/version_repository.dart';
import 'package:friends_bingo_app/src/core/version/version_update_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sampleUpdate = AndroidAppVersionModel(
  version: '2.4.1',
  versionCode: 5,
  minimumVersionCode: 3,
  downloadUrl: 'https://example.com/app-release.apk',
  sha256: 'c5ae01a502cc64e840b452537b19b73c52a7b5c6507661ec1334bf6ab4a090ff',
  releaseNotes: 'Bug fixes',
  forceUpdate: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VersionCheckController.evaluateForTest', () {
    test('returns none when installed build is up to date', () {
      final state = VersionCheckController.evaluateForTest(
        installedBuild: 5,
        remote: _sampleUpdate,
      );

      expect(state.kind, VersionCheckKind.none);
      expect(state.updateInfo, isNull);
      expect(state.remoteVersionCode, 5);
      expect(state.installedBuild, 5);
    });

    test('returns optional when installed build is below latest only', () {
      final state = VersionCheckController.evaluateForTest(
        installedBuild: 4,
        remote: _sampleUpdate,
      );

      expect(state.kind, VersionCheckKind.optional);
      expect(state.updateInfo, _sampleUpdate);
    });

    test('returns force when installed build is below minimum', () {
      final state = VersionCheckController.evaluateForTest(
        installedBuild: 2,
        remote: _sampleUpdate,
      );

      expect(state.kind, VersionCheckKind.force);
      expect(state.updateInfo, _sampleUpdate);
    });

    test('returns force when server sets forceUpdate', () {
      final state = VersionCheckController.evaluateForTest(
        installedBuild: 4,
        remote: const AndroidAppVersionModel(
          version: '2.4.1',
          versionCode: 5,
          minimumVersionCode: 3,
          downloadUrl: 'https://example.com/app-release.apk',
          sha256: '',
          releaseNotes: '',
          forceUpdate: true,
        ),
      );

      expect(state.kind, VersionCheckKind.force);
    });

    test('returns force when version label differs even if build is higher', () {
      final state = VersionCheckController.evaluateForTest(
        installedBuild: 2009,
        installedVersion: '1.0.8',
        remote: const AndroidAppVersionModel(
          version: '1.0.9',
          versionCode: 10,
          minimumVersionCode: 10,
          downloadUrl: 'https://friendsbingo.netlify.app/download',
          sha256: '',
          releaseNotes: '',
          forceUpdate: true,
        ),
      );

      expect(state.kind, VersionCheckKind.force);
    });
  });

  group('VersionCheckController.check', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('uses cached force requirement when network fails', () async {
      final prefs = await SharedPreferences.getInstance();
      final cache = VersionUpdateCache(prefs);
      await cache.saveForceRequirement(_sampleUpdate);

      final container = ProviderContainer(
        overrides: [
          installedBuildNumberReaderProvider.overrideWithValue(() async => 2),
          installedAppVersionProvider.overrideWith(
            (ref) async => const InstalledAppVersion(
              version: '1.0.0',
              buildNumber: 2,
            ),
          ),
          versionUpdateCacheProvider.overrideWith((ref) async => cache),
          versionRepositoryProvider.overrideWithValue(_FailingVersionRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(versionCheckControllerProvider.notifier);
      await controller.check();

      final state = container.read(versionCheckControllerProvider);
      expect(state.kind, VersionCheckKind.force);
      expect(state.updateInfo, _sampleUpdate);
    });

    test('returns none on network failure without cached force requirement', () async {
      final prefs = await SharedPreferences.getInstance();
      final cache = VersionUpdateCache(prefs);

      final container = ProviderContainer(
        overrides: [
          installedBuildNumberReaderProvider.overrideWithValue(() async => 2),
          installedAppVersionProvider.overrideWith(
            (ref) async => const InstalledAppVersion(
              version: '1.0.0',
              buildNumber: 2,
            ),
          ),
          versionUpdateCacheProvider.overrideWith((ref) async => cache),
          versionRepositoryProvider.overrideWithValue(_FailingVersionRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(versionCheckControllerProvider.notifier);
      await controller.check();

      expect(container.read(versionCheckControllerProvider).kind, VersionCheckKind.error);
    });

    test('persists force requirement after successful force check', () async {
      final prefs = await SharedPreferences.getInstance();
      final cache = VersionUpdateCache(prefs);

      final container = ProviderContainer(
        overrides: [
          installedBuildNumberReaderProvider.overrideWithValue(() async => 2),
          installedAppVersionProvider.overrideWith(
            (ref) async => const InstalledAppVersion(
              version: '1.0.0',
              buildNumber: 2,
            ),
          ),
          versionUpdateCacheProvider.overrideWith((ref) async => cache),
          versionRepositoryProvider.overrideWithValue(
            _StubVersionRepository(_sampleUpdate),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(versionCheckControllerProvider.notifier);
      await controller.check();

      expect(container.read(versionCheckControllerProvider).kind, VersionCheckKind.force);
      expect(cache.readForceRequirement(), _sampleUpdate);
    });
  });
}

class _StubVersionRepository implements VersionRepository {
  _StubVersionRepository(this._response);

  final AndroidAppVersionModel _response;

  @override
  Future<AndroidAppVersionModel> fetchAndroidVersion() async => _response;
}

class _FailingVersionRepository implements VersionRepository {
  @override
  Future<AndroidAppVersionModel> fetchAndroidVersion() {
    throw Exception('network');
  }
}
