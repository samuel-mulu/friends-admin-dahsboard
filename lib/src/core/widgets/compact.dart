import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Keeps a 48dp tap target while visually looking compact.
class CompactIconButton extends StatelessWidget {
  const CompactIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize = 18,
    this.visualSize = 32,
    this.tapTarget = 48,
    this.color,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;

  /// Visual button size inside a larger tap target.
  final double visualSize;

  /// Tap target size (keep ~48dp for accessibility).
  final double tapTarget;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return SizedBox(
      width: tapTarget,
      height: tapTarget,
      child: Center(
        child: SizedBox(
          width: visualSize,
          height: visualSize,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: Icon(
              icon,
              size: iconSize,
              color: enabled ? effectiveColor : effectiveColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// A standard card-like section container with compact padding.
class CompactPanel extends StatelessWidget {
  const CompactPanel({
    required this.child,
    this.padding = AppSpacing.cardPaddingDense,
    this.decoration,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

