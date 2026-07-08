import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/l10n/app_locale.dart';
import 'theme_mode_provider.dart';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final storageAsync = ref.watch(appPreferencesStorageProvider);
    return storageAsync.maybeWhen(
      data: (storage) => storage.readLocale() ?? kDefaultAppLocale,
      orElse: () => kDefaultAppLocale,
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writeLocale(locale);
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
