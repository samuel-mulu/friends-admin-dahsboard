import 'android_app_version_model.dart';

enum VersionCheckKind { none, optional, force, error }

class VersionCheckState {
  const VersionCheckState({
    required this.kind,
    this.updateInfo,
    this.installedBuild,
    this.remoteVersionCode,
    this.remoteVersionLabel,
  });

  final VersionCheckKind kind;
  final AndroidAppVersionModel? updateInfo;
  final int? installedBuild;
  final int? remoteVersionCode;
  final String? remoteVersionLabel;

  static const none = VersionCheckState(kind: VersionCheckKind.none);

  static const error = VersionCheckState(kind: VersionCheckKind.error);
}
