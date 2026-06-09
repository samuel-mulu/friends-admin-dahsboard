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
    this.reservationSecondsRemaining,
    super.key,
  });

  final int number;
  final CartelaAvailability availability;
  final VoidCallback onTap;
  final bool isRegistering;
  final int? reservationSecondsRemaining;

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
        isDark ? const Color(0xFF322A42) : const Color(0xFFD4CEDE),
        isDark ? const Color(0xFFB8B0C8) : const Color(0xFF4A425C),
        isDark ? const Color(0xFF8A7E9E) : const Color(0xFF7A708E),
      ),
      CartelaAvailability.reservedByMe => (
        AppBranding.casinoPurple.withValues(alpha: 0.75),
        AppBranding.gold,
        AppBranding.gold.withValues(alpha: 0.8),
      ),
      CartelaAvailability.reservedByOther => (
        isDark ? const Color(0xFF2E2840) : const Color(0xFFE0DAEA),
        isDark ? const Color(0xFF9890A8) : const Color(0xFF5E5670),
        isDark ? const Color(0xFF6E6680) : const Color(0xFF9088A0),
      ),
    };

    final borderWidth =
        availability == CartelaAvailability.taken ||
            availability == CartelaAvailability.reservedByOther
        ? 1.5
        : 1.0;

    final label = _chipLabel();

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
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
      final seconds = reservationSecondsRemaining;
      if (seconds != null && seconds > 0) {
        return '${seconds}s';
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
