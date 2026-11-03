import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_number_chip.dart';

/// Display presentation mode for registration cartelas.
enum RegistrationCartelaDisplayMode {
  /// Compact grid tile for 5-column / high-density browsing.
  tile,

  /// Full-width horizontal row card for list views.
  card,
}

/// A standalone, decoupled, reusable widget representing an individual cartela
/// during registration or selection mode.
///
/// Supports both [RegistrationCartelaDisplayMode.tile] for grids and
/// [RegistrationCartelaDisplayMode.card] for lists.
class RegistrationCartelaCard extends StatelessWidget {
  const RegistrationCartelaCard({
    required this.number,
    required this.availability,
    required this.onTap,
    this.onLongPress,
    this.displayMode = RegistrationCartelaDisplayMode.tile,
    this.isSelected = false,
    this.isRegistering = false,
    this.selectBlocked = false,
    this.selectModeEnabled = false,
    this.isReservePending = false,
    this.reservationSecondsRemaining,
    this.entryFee,
    this.subtitle,
    super.key,
  });

  /// The cartela catalog number (e.g., 42).
  final int number;

  /// The resolved availability state (available, mine, taken, etc.).
  final CartelaAvailability availability;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Optional callback for long-press inspection.
  final VoidCallback? onLongPress;

  /// Presentation layout mode (tile vs card).
  final RegistrationCartelaDisplayMode displayMode;

  /// Whether this cartela is currently selected in bulk mode.
  final bool isSelected;

  /// Whether a registration network call is in flight for this cartela.
  final bool isRegistering;

  /// Whether selecting this cartela is blocked (e.g. balance or cap limit).
  final bool selectBlocked;

  /// Whether multi-selection mode is currently active.
  final bool selectModeEnabled;

  /// Whether a temporary bulk reserve call is pending for this cartela.
  final bool isReservePending;

  /// Seconds remaining on a temporary reservation hold, if any.
  final int? reservationSecondsRemaining;

  /// Optional entry fee string to display in list card mode.
  final String? entryFee;

  /// Optional custom subtitle or hint.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: switch (displayMode) {
        RegistrationCartelaDisplayMode.tile => _buildTile(context),
        RegistrationCartelaDisplayMode.card => _buildCard(context),
      },
    );
  }

  Widget _buildTile(BuildContext context) {
    return CartelaNumberChip(
      number: number,
      availability: availability,
      onTap: onTap,
      onLongPress: onLongPress,
      isRegistering: isRegistering,
      isSelected: isSelected,
      selectBlocked: selectBlocked,
      selectModeEnabled: selectModeEnabled,
      isReservePending: isReservePending,
      reservationSecondsRemaining: reservationSecondsRemaining,
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final canTap = selectModeEnabled
        ? (isSelected || availability == CartelaAvailability.available) &&
            !isRegistering &&
            !selectBlocked
        : (availability == CartelaAvailability.available ||
                availability == CartelaAvailability.mine) &&
            !isRegistering &&
            !selectBlocked;

    final (badgeColor, textColor, statusText) = _resolveStatusVisuals(theme, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        onLongPress: onLongPress != null && !selectModeEnabled
            ? () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : isDark
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Cartela number pill
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Cartela information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cartela #$number',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null || entryFee != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? 'Fee: $entryFee',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status Badge or Checkbox
              if (selectModeEnabled) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: canTap ? (_) => onTap() : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ] else if (isRegistering) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, String) _resolveStatusVisuals(ThemeData theme, bool isDark) {
    if (reservationSecondsRemaining != null) {
      return (
        Colors.orange.withValues(alpha: 0.2),
        Colors.orange.shade800,
        'Hold ${reservationSecondsRemaining}s',
      );
    }
    return switch (availability) {
      CartelaAvailability.available => (
          AppBranding.bingoFreeGreen.withValues(alpha: 0.15),
          AppBranding.bingoFreeGreen,
          'Available',
        ),
      CartelaAvailability.mine => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          'Registered',
        ),
      CartelaAvailability.taken => (
          theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          theme.colorScheme.onErrorContainer,
          'Taken',
        ),
      CartelaAvailability.reservedByOther => (
          Colors.orange.withValues(alpha: 0.2),
          Colors.orange.shade800,
          'Reserved',
        ),
      CartelaAvailability.reservedByMe => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
          'Selected',
        ),
    };
  }
}
