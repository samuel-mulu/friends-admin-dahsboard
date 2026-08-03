import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/first_launch_preferences_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';

class FirstLaunchPreferencesScreen extends ConsumerStatefulWidget {
  const FirstLaunchPreferencesScreen({super.key});

  @override
  ConsumerState<FirstLaunchPreferencesScreen> createState() =>
      _FirstLaunchPreferencesScreenState();
}

class _FirstLaunchPreferencesScreenState
    extends ConsumerState<FirstLaunchPreferencesScreen> {
  static const _languages = [
    (code: 'en', name: 'English', native: 'English'),
    (code: 'am', name: 'Amharic', native: 'አማርኛ'),
    (code: 'om', name: 'Oromo', native: 'Afaan Oromoo'),
    (code: 'ti', name: 'Tigrinya', native: 'ትግርኛ'),
  ];

  late ThemeMode _draftThemeMode;
  late Locale _draftLocale;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _draftThemeMode = ref.read(themeModeProvider);
    _draftLocale = ref.read(localeProvider);
  }

  Future<void> _onContinue() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(firstLaunchPreferencesCompletedProvider.notifier)
          .complete(themeMode: _draftThemeMode, locale: _draftLocale);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onSkip() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(firstLaunchPreferencesCompletedProvider.notifier).skip();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Brightness _previewBrightness(BuildContext context) {
    return switch (_draftThemeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final previewBrightness = _previewBrightness(context);
    final isDarkPreview = previewBrightness == Brightness.dark;
    final scaffoldColor = isDarkPreview
        ? AppBranding.liveSurfaceDark
        : AppBranding.lightScaffold;
    final cardColor = isDarkPreview
        ? AppBranding.liveCardDark
        : AppBranding.lightSurfaceRaised;
    final borderColor = isDarkPreview
        ? AppBranding.gold.withValues(alpha: 0.28)
        : AppBranding.lightOutline;
    final accent = isDarkPreview ? AppBranding.gold : AppBranding.brandPurple;
    final foreground = isDarkPreview
        ? Colors.white
        : AppBranding.lightOnSurface;
    final muted = isDarkPreview
        ? Colors.white.withValues(alpha: 0.72)
        : AppBranding.lightOnSurfaceMuted;

    return PopScope(
      canPop: false,
      child: Material(
        color: scaffoldColor,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxxl,
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppBranding.brandName,
                              textAlign: TextAlign.center,
                              style: AppBranding.wordmarkBrandAccent(
                                context,
                                size: 30,
                              ).copyWith(color: accent),
                            ),
                            VGap.xxl,
                            Text(
                              l10n.firstLaunchPreferencesTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDarkPreview
                                    ? Colors.white
                                    : AppBranding.brandPurple,
                              ),
                            ),
                            VGap.md,
                            Text(
                              l10n.firstLaunchPreferencesSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                                height: 1.35,
                              ),
                            ),
                            const VGap(AppSpacing.xxxl),
                            _SectionLabel(label: l10n.theme, color: accent),
                            VGap.md,
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 360;
                                final cards = ThemeMode.values
                                    .map((mode) {
                                      return _ThemeChoiceCard(
                                        key: Key(
                                          'first_launch_theme_${mode.name}',
                                        ),
                                        mode: mode,
                                        selected: _draftThemeMode == mode,
                                        enabled: !_isSubmitting,
                                        label: _themeLabel(l10n, mode),
                                        accent: accent,
                                        foreground: foreground,
                                        cardColor: cardColor,
                                        borderColor: borderColor,
                                        onTap: () {
                                          setState(
                                            () => _draftThemeMode = mode,
                                          );
                                        },
                                      );
                                    })
                                    .toList(growable: false);

                                if (!wide) {
                                  return Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < cards.length;
                                        i++
                                      ) ...[
                                        cards[i],
                                        if (i < cards.length - 1) VGap.md,
                                      ],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      Expanded(child: cards[i]),
                                      if (i < cards.length - 1)
                                        const SizedBox(width: AppSpacing.md),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const VGap(AppSpacing.xxxl),
                            _SectionLabel(label: l10n.language, color: accent),
                            VGap.md,
                            ..._languages.map((lang) {
                              final selected =
                                  _draftLocale.languageCode == lang.code;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _LanguageChoiceCard(
                                  key: Key('first_launch_lang_${lang.code}'),
                                  native: lang.native,
                                  name: lang.name,
                                  selected: selected,
                                  enabled: !_isSubmitting,
                                  accent: accent,
                                  foreground: foreground,
                                  mutedForeground: muted,
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  onTap: () {
                                    setState(
                                      () => _draftLocale = Locale(lang.code),
                                    );
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    VGap.xl,
                    FilledButton(
                      key: const Key('first_launch_continue'),
                      onPressed: _isSubmitting
                          ? null
                          : () => unawaited(_onContinue()),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppBranding.casinoPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppBranding.casinoPurple
                            .withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.firstLaunchPreferencesContinue,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    VGap.md,
                    TextButton(
                      key: const Key('first_launch_skip'),
                      onPressed: _isSubmitting
                          ? null
                          : () => unawaited(_onSkip()),
                      child: Text(
                        l10n.firstLaunchPreferencesSkip,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeAuto,
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  const _ThemeChoiceCard({
    super.key,
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.label,
    required this.accent,
    required this.foreground,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final bool enabled;
  final String label;
  final Color accent;
  final Color foreground;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(_icon, color: accent, size: 22),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: selected
                        ? accent
                        : Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              VGap.md,
              _ThemePreviewStrip(mode: mode),
              VGap.md,
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewStrip extends StatelessWidget {
  const _ThemePreviewStrip({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final isDark = switch (mode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  AppBranding.casinoPurpleDeep,
                  AppBranding.casinoPurple,
                  AppBranding.liveCardDark,
                ]
              : const [
                  AppBranding.lightSurfaceRaised,
                  AppBranding.lightSurface,
                  AppBranding.lightSurfaceMuted,
                ],
        ),
        border: Border.all(
          color: isDark
              ? AppBranding.gold.withValues(alpha: 0.35)
              : AppBranding.lightOutline,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isDark ? AppBranding.gold : AppBranding.brandPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.28)
                    : AppBranding.brandPurple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChoiceCard extends StatelessWidget {
  const _LanguageChoiceCard({
    super.key,
    required this.native,
    required this.name,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.foreground,
    required this.mutedForeground,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  final String native;
  final String name;
  final bool selected;
  final bool enabled;
  final Color accent;
  final Color foreground;
  final Color mutedForeground;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      native,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (native != name) ...[
                      VGap.xs,
                      Text(
                        name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? accent : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
