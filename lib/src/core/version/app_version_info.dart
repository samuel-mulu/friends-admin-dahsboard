import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InstalledAppVersion {
  const InstalledAppVersion({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final int buildNumber;

  String get label => '$version ($buildNumber)';
}

final installedAppVersionProvider = FutureProvider<InstalledAppVersion>((
  ref,
) async {
  final info = await PackageInfo.fromPlatform();
  return InstalledAppVersion(
    version: info.version,
    buildNumber: int.tryParse(info.buildNumber) ?? 0,
  );
});
