import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences_storage.dart';

final appPreferencesStorageProvider =
    FutureProvider<AppPreferencesStorage>((ref) async {
  return AppPreferencesStorage.create();
});

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final storageAsync = ref.watch(appPreferencesStorageProvider);
    return storageAsync.maybeWhen(
      data: (storage) => storage.readThemeMode(),
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writeThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
