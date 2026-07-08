import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'android_app_version_model.dart';
import 'app_version_info.dart';
import 'version_check_state.dart';
import 'version_repository.dart';
import 'version_update_cache.dart';

typedef InstalledBuildNumberReader = Future<int> Function();

final installedBuildNumberReaderProvider = Provider<InstalledBuildNumberReader>(
  (ref) {
    return () async {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber) ?? 0;
    };
  },
);

class VersionCheckController extends Notifier<VersionCheckState> {
  InstalledBuildNumberReader? _installedBuildNumberReaderOverride;

  @override
  VersionCheckState build() {
    Future.microtask(_hydrateForceRequirementFromCache);
    return VersionCheckState.none;
  }

  Future<void> _hydrateForceRequirementFromCache() async {
    try {
      final cache = await ref.read(versionUpdateCacheProvider.future);
      final cached = cache.readForceRequirement();
      if (cached == null || !ref.mounted) {
        return;
      }

      final installedBuild = await _readInstalledBuildNumber();
      if (!ref.mounted) {
        return;
      }

      state = VersionCheckState(
        kind: VersionCheckKind.force,
        updateInfo: cached,
        installedBuild: installedBuild,
      );
    } catch (error, stackTrace) {
      debugPrint('Cached force-update hydrate failed: $error');
      debugPrint('$stackTrace');
    }
  }

  @visibleForTesting
  void setInstalledBuildNumberReaderForTest(InstalledBuildNumberReader reader) {
    _installedBuildNumberReaderOverride = reader;
  }

  Future<void> check() async {
    final installed = await _readInstalledVersion();

    try {
      final remote = await ref.read(versionRepositoryProvider).fetchAndroidVersion();
      final nextState = _VersionCheckEvaluator.evaluate(
        installedBuild: installed.build,
        installedVersion: installed.version,
        remote: remote,
      );
      final cache = await ref.read(versionUpdateCacheProvider.future);

      if (nextState.kind == VersionCheckKind.force && nextState.updateInfo != null) {
        await cache.saveForceRequirement(nextState.updateInfo!);
      } else {
        await cache.clearForceRequirement();
      }

      state = nextState;
    } catch (error, stackTrace) {
      debugPrint('Version check failed: $error');
      debugPrint('$stackTrace');

      final cache = await ref.read(versionUpdateCacheProvider.future);
      final cached = cache.readForceRequirement();
      if (cached != null) {
        state = VersionCheckState(
          kind: VersionCheckKind.force,
          updateInfo: cached,
          installedBuild: installed.build,
        );
        return;
      }

      state = VersionCheckState(
        kind: VersionCheckKind.error,
        installedBuild: installed.build,
      );
    }
  }

  Future<({int build, String version})> _readInstalledVersion() async {
    if (_installedBuildNumberReaderOverride != null) {
      final build = await _installedBuildNumberReaderOverride!();
      return (build: build, version: '');
    }

    final installed = await ref.read(installedAppVersionProvider.future);
    return (build: installed.buildNumber, version: installed.version.trim());
  }

  Future<int> _readInstalledBuildNumber() {
    final InstalledBuildNumberReader reader =
        _installedBuildNumberReaderOverride ??
        ref.read(installedBuildNumberReaderProvider);
    return reader();
  }

  @visibleForTesting
  static VersionCheckState evaluateForTest({
    required int installedBuild,
    required AndroidAppVersionModel remote,
    String? installedVersion,
  }) {
    return _VersionCheckEvaluator.evaluate(
      installedBuild: installedBuild,
      installedVersion: installedVersion ?? remote.version,
      remote: remote,
    );
  }
}

class _VersionCheckEvaluator {
  static VersionCheckState evaluate({
    required int installedBuild,
    required String installedVersion,
    required AndroidAppVersionModel remote,
  }) {
    final diagnostics = VersionCheckState(
      kind: VersionCheckKind.none,
      installedBuild: installedBuild,
      remoteVersionCode: remote.versionCode,
      remoteVersionLabel: remote.version,
    );

    final buildUpToDate = installedBuild >= remote.versionCode;
    final versionUpToDate =
        installedVersion.isEmpty ||
        _normalizeVersion(installedVersion) ==
            _normalizeVersion(remote.version);

    if (buildUpToDate && versionUpToDate) {
      return diagnostics;
    }

    final belowLatestBuild = installedBuild < remote.versionCode;

    if (belowLatestBuild &&
        (remote.forceUpdate || installedBuild < remote.minimumVersionCode)) {
      return VersionCheckState(
        kind: VersionCheckKind.force,
        updateInfo: remote,
        installedBuild: installedBuild,
        remoteVersionCode: remote.versionCode,
        remoteVersionLabel: remote.version,
      );
    }

    if (!versionUpToDate && remote.forceUpdate) {
      return VersionCheckState(
        kind: VersionCheckKind.force,
        updateInfo: remote,
        installedBuild: installedBuild,
        remoteVersionCode: remote.versionCode,
        remoteVersionLabel: remote.version,
      );
    }

    if (belowLatestBuild || !versionUpToDate) {
      return VersionCheckState(
        kind: VersionCheckKind.optional,
        updateInfo: remote,
        installedBuild: installedBuild,
        remoteVersionCode: remote.versionCode,
        remoteVersionLabel: remote.version,
      );
    }

    return diagnostics;
  }

  static String _normalizeVersion(String value) => value.trim();
}

final versionCheckControllerProvider =
    NotifierProvider<VersionCheckController, VersionCheckState>(
      VersionCheckController.new,
    );

class VersionCheckReadyController extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() => state = true;
}

/// Set to true once startup bootstrap no longer needs to wait on version check.
final versionCheckReadyProvider =
    NotifierProvider<VersionCheckReadyController, bool>(
      VersionCheckReadyController.new,
    );
