import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/auth_device_session.dart';

Future<AuthSessionDeviceMeta> buildAuthDeviceMeta() async {
  final info = await PackageInfo.fromPlatform();
  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.windows => 'windows',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.linux => 'linux',
    _ => 'unknown',
  };

  String? deviceLabel;
  try {
    deviceLabel = Platform.localHostname;
  } catch (_) {
    deviceLabel = null;
  }

  return AuthSessionDeviceMeta(
    platform: platform,
    deviceLabel: deviceLabel,
    userAgent: '${info.appName}/${info.version} (${info.buildNumber})',
  );
}
