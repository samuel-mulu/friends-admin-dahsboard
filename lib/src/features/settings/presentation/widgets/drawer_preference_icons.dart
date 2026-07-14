import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';

/// Compact theme + language icon buttons with dropdown menus.
class DrawerPreferenceIcons extends ConsumerWidget {
  const DrawerPreferenceIcons({super.key});

  static const _languages = [
    (code: 'en', label: 'English'),
    (code: 'am', label: 'አማርኛ'),
    (code: 'om', label: 'Afaan Oromoo'),
    (code: 'ti', label: 'ትግርኛ'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final localeCode = ref.watch(localeProvider).languageCode;
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<ThemeMode>(
          tooltip: l10n.drawerTheme,
          padding: EdgeInsets.zero,
          offset: const Offset(0, 36),
          onSelected: (mode) {
            unawaited(themeNotifier.setThemeMode(mode));
          },
          itemBuilder: (context) => [
            for (final mode in ThemeMode.values)
              CheckedPopupMenuItem<ThemeMode>(
                value: mode,
                checked: themeMode == mode,
                child: Text(_themeLabel(l10n, mode)),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _themeIcon(themeMode),
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.language,
          padding: EdgeInsets.zero,
          offset: const Offset(0, 36),
          onSelected: (code) {
            unawaited(localeNotifier.setLocale(Locale(code)));
          },
          itemBuilder: (context) => [
            for (final item in _languages)
              CheckedPopupMenuItem<String>(
                value: item.code,
                checked: localeCode == item.code,
                child: Text(item.label),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  localeCode.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.drawerThemeLight,
      ThemeMode.dark => l10n.drawerThemeDark,
      ThemeMode.system => l10n.drawerThemeAuto,
    };
  }
}
