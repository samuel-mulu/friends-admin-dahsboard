import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/admin_broadcast_model.dart';

/// Shared visual tokens for admin notification surfaces.
abstract final class BroadcastMessageUi {
  static Color accentFor(AdminBroadcastCategory category, ColorScheme colors) {
    switch (category) {
      case AdminBroadcastCategory.dismissible:
        return AppBranding.goldDark;
      case AdminBroadcastCategory.persistent:
        return colors.primary;
      case AdminBroadcastCategory.forced:
        return colors.error;
    }
  }

  static IconData iconFor(AdminBroadcastCategory category) {
    switch (category) {
      case AdminBroadcastCategory.dismissible:
        return Icons.notifications_rounded;
      case AdminBroadcastCategory.persistent:
        return Icons.push_pin_rounded;
      case AdminBroadcastCategory.forced:
        return Icons.campaign_rounded;
    }
  }

  static Color sheetBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppBranding.liveCardDark
        : AppBranding.lightSurfaceRaised;
  }

  static Color tileBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppBranding.statPillDark
        : Colors.white;
  }

  static Color cardBackground(BuildContext context) => tileBackground(context);

  static Color bannerBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppBranding.statPillDark
        : Colors.white;
  }

  static Widget leadingIcon({
    required BuildContext context,
    required AdminBroadcastCategory category,
    double size = 40,
  }) {
    final theme = Theme.of(context);
    final accent = accentFor(category, theme.colorScheme);
    final iconSize = size * 0.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconFor(category),
        color: accent,
        size: iconSize,
      ),
    );
  }

  static String relativeTime(DateTime createdAt) {
    final local = createdAt.toLocal();
    final difference = DateTime.now().difference(local);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static EdgeInsets get sheetPadding =>
      const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.jumbo);
}
