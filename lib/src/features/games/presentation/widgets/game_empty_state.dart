import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/game_category_theme.dart';
import '../../data/models/game_model.dart';

/// Shared empty-state layout for games surfaces.
class GameEmptyState extends StatelessWidget {
  const GameEmptyState({
    required this.title,
    required this.body,
    this.category,
    this.icon,
    this.action,
    super.key,
  });

  factory GameEmptyState.noScheduledGame({
    required String title,
    required String body,
    Widget? action,
  }) {
    return GameEmptyState(
      title: title,
      body: body,
      category: GameCategory.normal,
      action: action,
    );
  }

  factory GameEmptyState.forCategory({
    required GameCategory category,
    required String title,
    required String body,
    Widget? action,
  }) {
    return GameEmptyState(
      category: category,
      title: title,
      body: body,
      action: action,
    );
  }

  final String title;
  final String body;
  final GameCategory? category;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedCategory = category ?? GameCategory.normal;
    final resolvedIcon = icon ?? GameCategoryTheme.iconFor(resolvedCategory);
    final accent = GameCategoryTheme.accentColor(
      resolvedCategory,
      isDark: isDark,
    );

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resolvedIcon, size: 52, color: accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
