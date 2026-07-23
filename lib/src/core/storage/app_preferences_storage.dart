import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/games/domain/cartela_mark_color.dart';
import '../../features/games/presentation/utils/cartela_marked_pattern_evaluator.dart';

class AppPreferencesStorage {
  AppPreferencesStorage(this._prefs);

  static const _themeModeKey = 'theme_mode';
  static const _realtimeBrandingSplashSeenKey = 'realtime_branding_splash_seen';
  static const _localeKey = 'app_locale';
  static const _cartelaMarkColorKey = 'cartela_mark_color';
  static const _cartelaSortModeKey = 'cartela_sort_mode';
  static const _profileAvatarPrefix = 'profile_avatar_';
  static const _dismissedGameAnnouncementsKey = 'dismissed_game_announcements';
  static const _cbeWithdrawAccountPrefix = 'cbe_withdraw_account_';
  static const defaultCbeWithdrawAccount = '1000';

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
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
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

  Locale? readLocale() {
    final value = _prefs.getString(_localeKey);
    if (value == null) return null;
    return Locale(value);
  }

  Future<void> writeLocale(Locale locale) {
    return _prefs.setString(_localeKey, locale.languageCode);
  }

  CartelaMarkColor readCartelaMarkColor() {
    return CartelaMarkColor.tryParse(_prefs.getString(_cartelaMarkColorKey)) ??
        CartelaMarkColor.green;
  }

  Future<void> writeCartelaMarkColor(CartelaMarkColor color) {
    return _prefs.setString(_cartelaMarkColorKey, color.storageKey);
  }

  CartelaSortMode readCartelaSortMode() {
    return CartelaSortMode.tryParse(_prefs.getString(_cartelaSortModeKey)) ??
        CartelaSortMode.manual;
  }

  Future<void> writeCartelaSortMode(CartelaSortMode mode) {
    return _prefs.setString(_cartelaSortModeKey, mode.storageKey);
  }

  String? readProfileAvatarId(String userId) {
    return _prefs.getString(_profileAvatarKey(userId));
  }

  Future<void> writeProfileAvatarId(String userId, String avatarId) {
    return _prefs.setString(_profileAvatarKey(userId), avatarId);
  }

  Future<void> clearProfileAvatarId(String userId) {
    return _prefs.remove(_profileAvatarKey(userId));
  }

  List<String> readDismissedGameAnnouncements() {
    return _prefs.getStringList(_dismissedGameAnnouncementsKey) ??
        const <String>[];
  }

  Future<void> writeDismissedGameAnnouncements(List<String> ids) {
    return _prefs.setStringList(_dismissedGameAnnouncementsKey, ids);
  }

  String readCbeWithdrawAccount(String userId) {
    final saved = _prefs.getString(_cbeWithdrawAccountKey(userId))?.trim();
    if (saved == null || saved.isEmpty) {
      return defaultCbeWithdrawAccount;
    }
    return saved;
  }

  Future<void> writeCbeWithdrawAccount(String userId, String account) {
    final trimmed = account.trim();
    if (trimmed.isEmpty) {
      return _prefs.remove(_cbeWithdrawAccountKey(userId));
    }
    return _prefs.setString(_cbeWithdrawAccountKey(userId), trimmed);
  }

  String _profileAvatarKey(String userId) {
    return '$_profileAvatarPrefix$userId';
  }

  String _cbeWithdrawAccountKey(String userId) {
    return '$_cbeWithdrawAccountPrefix$userId';
  }
}
