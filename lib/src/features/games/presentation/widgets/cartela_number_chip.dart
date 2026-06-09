import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../domain/cartela_availability.dart';

/// Compact cartela pick chip — number only, status by color.
class CartelaNumberChip extends StatelessWidget {
  const CartelaNumberChip({
    required this.number,
    required this.availability,
    required this.onTap,
    this.isRegistering = false,
    this.reservationExpiresAt,
    super.key,
  });

  final int number;
  final CartelaAvailability availability;
  final VoidCallback onTap;
  final bool isRegistering;
  final DateTime? reservationExpiresAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canTap = availability == CartelaAvailability.available && !isRegistering;

    final isDark = theme.brightness == Brightness.dark;
    final (background, foreground, borderColor) = switch (availability) {
      CartelaAvailability.available => (
        isDark ? const Color(0xFF2A2340) : theme.colorScheme.surface,
        theme.colorScheme.onSurface,
        AppBranding.gold.withValues(alpha: 0.5),
      ),
      CartelaAvailability.mine => (
        AppBranding.casinoPurple,
        AppBranding.gold,
        AppBranding.gold,
      ),
      CartelaAvailability.taken => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.5 : 0.4),
        theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
      CartelaAvailability.reservedByMe => (
        AppBranding.casinoPurple.withValues(alpha: 0.75),
        AppBranding.gold,
        AppBranding.gold.withValues(alpha: 0.8),
      ),
      CartelaAvailability.reservedByOther => (
        theme.colorScheme.surfaceContainerHigh,
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.45 : 0.35),
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
    };

    final label = _chipLabel();

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: isRegistering
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppBranding.gold,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: label == number.toString() ? 10 : 8,
                ),
              ),
      ),
    );
  }

  String _chipLabel() {
    if (availability == CartelaAvailability.reservedByOther) {
      return 'Choosing…';
    }

    if (availability == CartelaAvailability.reservedByMe) {
      final expiresAt = reservationExpiresAt;
      if (expiresAt != null) {
        final seconds = expiresAt.difference(DateTime.now()).inSeconds;
        if (seconds > 0) {
          return '${seconds}s';
        }
      }
      return 'Confirming…';
    }

    if (availability == CartelaAvailability.mine) {
      return 'Yours';
    }

    if (availability == CartelaAvailability.taken) {
      return 'Taken';
    }

    return '$number';
  }
}
