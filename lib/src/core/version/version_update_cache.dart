import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android_app_version_model.dart';

class VersionUpdateCache {
  VersionUpdateCache(this._prefs);

  static const _forceRequirementKey = 'app_update.force_requirement';

  final SharedPreferences _prefs;

  AndroidAppVersionModel? readForceRequirement() {
    final raw = _prefs.getString(_forceRequirementKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return AndroidAppVersionModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveForceRequirement(AndroidAppVersionModel info) {
    return _prefs.setString(_forceRequirementKey, jsonEncode(info.toJson()));
  }

  Future<void> clearForceRequirement() {
    return _prefs.remove(_forceRequirementKey);
  }
}

final versionUpdateCacheProvider = FutureProvider<VersionUpdateCache>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return VersionUpdateCache(prefs);
});
