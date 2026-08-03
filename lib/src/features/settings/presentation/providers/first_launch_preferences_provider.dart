import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';
import 'theme_mode_provider.dart';

class FirstLaunchPreferencesController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = await ref.watch(appPreferencesStorageProvider.future);
    return storage.hasCompletedFirstLaunchPreferences();
  }

  Future<void> complete({
    required ThemeMode themeMode,
    required Locale locale,
  }) async {
    await ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
    await ref.read(localeProvider.notifier).setLocale(locale);
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.markFirstLaunchPreferencesCompleted();
    state = const AsyncData(true);
  }

  Future<void> skip() async {
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.markFirstLaunchPreferencesCompleted();
    state = const AsyncData(true);
  }
}

final firstLaunchPreferencesCompletedProvider =
    AsyncNotifierProvider<FirstLaunchPreferencesController, bool>(
      FirstLaunchPreferencesController.new,
    );
