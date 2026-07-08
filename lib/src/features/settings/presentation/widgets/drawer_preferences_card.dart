import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';
import 'language_picker_sheet.dart';

class DrawerPreferencesCard extends ConsumerWidget {
  const DrawerPreferencesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final localeCode = ref.watch(localeProvider).languageCode.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppBranding.panelBackground(context),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppBranding.panelBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DrawerPreferenceTile(
              icon: _themeIcon(themeMode),
              label: l10n.drawerTheme,
              onTap: () => _showThemePicker(context, ref),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          Expanded(
            child: _DrawerPreferenceTile(
              icon: Icons.language_rounded,
              label: l10n.language,
              trailingLabel: localeCode,
              onTap: () => showLanguagePickerSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.read(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.drawerTheme,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ...ThemeMode.values.map((mode) {
                  final selected = themeMode == mode;
                  return ListTile(
                    leading: Icon(_themeIcon(mode)),
                    title: Text(_themeLabel(l10n, mode)),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      unawaited(notifier.setThemeMode(mode));
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _themeLabel(dynamic l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.drawerThemeLight,
      ThemeMode.dark => l10n.drawerThemeDark,
      ThemeMode.system => l10n.drawerThemeAuto,
    };
  }
}

class _DrawerPreferenceTile extends StatelessWidget {
  const _DrawerPreferenceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                const SizedBox(width: 4),
                Text(
                  trailingLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
