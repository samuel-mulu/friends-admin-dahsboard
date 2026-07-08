import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/admin_broadcast_model.dart';

abstract final class BroadcastMessageUi {
  static Color accentFor(AdminBroadcastCategory category, ColorScheme colors) {
    switch (category) {
      case AdminBroadcastCategory.dismissible:
        return AppBranding.gold;
      case AdminBroadcastCategory.persistent:
        return colors.primary;
      case AdminBroadcastCategory.forced:
        return colors.error;
    }
  }

  static IconData iconFor(AdminBroadcastCategory category) {
    switch (category) {
      case AdminBroadcastCategory.dismissible:
        return Icons.notifications_active_rounded;
      case AdminBroadcastCategory.persistent:
        return Icons.push_pin_rounded;
      case AdminBroadcastCategory.forced:
        return Icons.report_rounded;
    }
  }

  static Color sheetBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppBranding.liveCardDark
        : AppBranding.lightSurfaceRaised;
  }

  static Color cardBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppBranding.statPillDark
        : Colors.white;
  }

  static BoxDecoration cardDecoration({
    required BuildContext context,
    required AdminBroadcastCategory category,
  }) {
    final theme = Theme.of(context);

    return BoxDecoration(
      color: cardBackground(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.35 : 0.55,
        ),
      ),
      boxShadow: theme.brightness == Brightness.light
          ? [
              BoxShadow(
                color: AppBranding.brandPurple.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  static Widget leadingIcon({
    required BuildContext context,
    required AdminBroadcastCategory category,
  }) {
    final theme = Theme.of(context);
    final accent = accentFor(category, theme.colorScheme);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconFor(category),
        color: accent,
        size: 22,
      ),
    );
  }

  static EdgeInsets get sheetPadding =>
      const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.jumbo);
}
