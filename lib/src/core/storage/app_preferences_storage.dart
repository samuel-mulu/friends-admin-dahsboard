import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesStorage {
  AppPreferencesStorage(this._prefs);

  static const _themeModeKey = 'theme_mode';
  static const _realtimeBrandingSplashSeenKey =
      'realtime_branding_splash_seen';

  final SharedPreferences _prefs;

  static Future<AppPreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferencesStorage(prefs);
  }

  ThemeMode readThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  bool hasSeenRealtimeBrandingSplash() {
    return _prefs.getBool(_realtimeBrandingSplashSeenKey) ??
        _prefs.getBool('branding_splash_seen') ??
        false;
  }

  Future<void> markRealtimeBrandingSplashSeen() {
    return _prefs.setBool(_realtimeBrandingSplashSeenKey, true);
  }

  Future<void> writeThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(_themeModeKey, value);
  }
}
