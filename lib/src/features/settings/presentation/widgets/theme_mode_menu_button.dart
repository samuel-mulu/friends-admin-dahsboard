import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../providers/theme_mode_provider.dart';

class ThemeModeMenuButton extends ConsumerWidget {
  const ThemeModeMenuButton({this.iconColor, super.key});

  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return PopupMenuButton<ThemeMode>(
      tooltip: l10n.drawerTheme,
      icon: Icon(Icons.dark_mode_outlined, color: iconColor),
      onSelected: notifier.setThemeMode,
      itemBuilder: (context) {
        const modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
        return modes
            .map(
              (mode) => PopupMenuItem<ThemeMode>(
                value: mode,
                child: _ThemeModeMenuRow(
                  label: _labelForMode(l10n, mode),
                  selected: themeMode == mode,
                ),
              ),
            )
            .toList(growable: false);
      },
    );
  }

  String _labelForMode(dynamic l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.drawerThemeLight,
      ThemeMode.dark => l10n.drawerThemeDark,
      ThemeMode.system => l10n.drawerThemeAuto,
    };
  }
}

class _ThemeModeMenuRow extends StatelessWidget {
  const _ThemeModeMenuRow({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: selected
              ? Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.primary)
              : null,
        ),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
