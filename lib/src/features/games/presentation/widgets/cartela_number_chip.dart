import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_branding.dart';
import '../../domain/cartela_availability.dart';

/// Compact cartela pick chip — number-first for available, status labels for mine/taken.
class CartelaNumberChip extends StatelessWidget {
  const CartelaNumberChip({
    required this.number,
    required this.availability,
    required this.onTap,
    this.onLongPress,
    this.isRegistering = false,
    this.isSelected = false,
    this.selectBlocked = false,
    this.selectModeEnabled = false,
    this.isReservePending = false,
    this.reservationSecondsRemaining,
    super.key,
  });

  final int number;
  final CartelaAvailability availability;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isRegistering;
  final bool isSelected;
  final bool selectBlocked;
  final bool selectModeEnabled;
  final bool isReservePending;
  final int? reservationSecondsRemaining;

  static const _statusFontSize = 11.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canTap = selectModeEnabled
        ? (isSelected || availability == CartelaAvailability.available) &&
              !isRegistering &&
              !selectBlocked
        : availability == CartelaAvailability.available &&
              !isRegistering &&
              !selectBlocked;

    final style = _ChipStyle.resolve(
      context: context,
      availability: availability,
      isSelected: isSelected,
      selectModeEnabled: selectModeEnabled,
      isReservePending: isReservePending,
      isDark: isDark,
      theme: theme,
    );

    final canLongPress =
        !selectModeEnabled &&
        onLongPress != null &&
        availability == CartelaAvailability.available &&
        !isRegistering &&
        !selectBlocked;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      onLongPress: canLongPress
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress!();
            }
          : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: style.borderColor,
            width: style.borderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: _ChipContent(
            number: number,
            availability: availability,
            isRegistering: isRegistering,
            isSelected: isSelected,
            isReservePending: isReservePending,
            selectModeEnabled: selectModeEnabled,
            reservationSecondsRemaining: reservationSecondsRemaining,
            foreground: style.foreground,
            showLargeNumber: style.showLargeNumber,
            statusLabel: style.statusLabel,
          ),
        ),
      ),
    );
  }
}

class _ChipStyle {
  const _ChipStyle({
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.borderWidth,
    required this.showLargeNumber,
    this.statusLabel,
  });

  final Color background;
  final Color foreground;
  final Color borderColor;
  final double borderWidth;
  final bool showLargeNumber;
  final String? statusLabel;

  static _ChipStyle resolve({
    required BuildContext context,
    required CartelaAvailability availability,
    required bool isSelected,
    required bool selectModeEnabled,
    required bool isReservePending,
    required bool isDark,
    required ThemeData theme,
  }) {
    if (isSelected) {
      // In select mode we want a clear "filled" selected state (not just border),
      // matching the reserved-by-me affordance so it's easy to see at a glance.
      final selectedBackground = selectModeEnabled
          ? AppBranding.cartelaChipSelectedBackground(context).withValues(
              alpha: isDark ? 1 : 0.28,
            )
          : AppBranding.cartelaChipSelectedBackground(context);
      return _ChipStyle(
        background: selectedBackground,
        foreground: isDark ? AppBranding.gold : AppBranding.brandPurple,
        borderColor: isReservePending
            ? AppBranding.goldAccent
            : AppBranding.gold,
        borderWidth: isReservePending ? 2.5 : 2,
        showLargeNumber: true,
      );
    }

    return switch (availability) {
      CartelaAvailability.available => _ChipStyle(
        background: AppBranding.cartelaChipAvailableBackground(context),
        foreground: AppBranding.cartelaChipAvailableForeground(context),
        borderColor: AppBranding.cartelaChipAvailableBorder(context),
        borderWidth: 1,
        showLargeNumber: true,
      ),
      CartelaAvailability.mine => _ChipStyle(
        background: AppBranding.cartelaChipMineBackground(context),
        foreground: AppBranding.cartelaChipMineForeground(context),
        borderColor: AppBranding.cartelaChipMineBorder(context),
        borderWidth: 1,
        showLargeNumber: false,
        statusLabel: 'Yours',
      ),
      CartelaAvailability.taken => _ChipStyle(
        background: AppBranding.cartelaChipTakenBackground(context),
        foreground: AppBranding.cartelaChipTakenForeground(context),
        borderColor: AppBranding.cartelaChipTakenBorder(context),
        borderWidth: 1,
        showLargeNumber: false,
        statusLabel: 'Taken',
      ),
      CartelaAvailability.reservedByMe => _ChipStyle(
        background: isDark
            ? AppBranding.casinoPurple.withValues(alpha: 0.82)
            : AppBranding.lightSurfaceRaised,
        foreground: isDark ? AppBranding.gold : AppBranding.brandPurple,
        borderColor: AppBranding.gold.withValues(alpha: isDark ? 0.9 : 0.75),
        borderWidth: 1.5,
        showLargeNumber: true,
      ),
      CartelaAvailability.reservedByOther => _ChipStyle(
        background: AppBranding.cartelaChipReservedByOtherBackground(context),
        foreground: AppBranding.cartelaChipReservedByOtherForeground(context),
        borderColor: AppBranding.cartelaChipTakenBorder(context),
        borderWidth: 1.5,
        showLargeNumber: false,
        statusLabel: 'Res',
      ),
    };
  }
}

class _ChipContent extends StatelessWidget {
  const _ChipContent({
    required this.number,
    required this.availability,
    required this.isRegistering,
    required this.isSelected,
    required this.isReservePending,
    required this.selectModeEnabled,
    required this.reservationSecondsRemaining,
    required this.foreground,
    required this.showLargeNumber,
    this.statusLabel,
  });

  final int number;
  final CartelaAvailability availability;
  final bool isRegistering;
  final bool isSelected;
  final bool isReservePending;
  final bool selectModeEnabled;
  final int? reservationSecondsRemaining;
  final Color foreground;
  final bool showLargeNumber;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isRegistering) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.35,
            child: _NumberLabel(
              label: '$number',
              color: foreground,
              large: true,
            ),
          ),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppBranding.goldAccent,
            ),
          ),
        ],
      );
    }

    if (isReservePending && isSelected) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.7,
            child: _NumberLabel(
              label: '$number',
              color: foreground,
              large: showLargeNumber,
            ),
          ),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppBranding.goldAccent,
            ),
          ),
        ],
      );
    }

    if (statusLabel != null) {
      return Text(
        statusLabel!,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: CartelaNumberChip._statusFontSize,
          letterSpacing: 0.2,
        ),
      );
    }

    final label = _primaryLabel();

    Widget content = _NumberLabel(
      label: label,
      color: foreground,
      large: showLargeNumber,
    );

    if (availability == CartelaAvailability.reservedByMe && !selectModeEnabled) {
      final seconds = reservationSecondsRemaining;
      if (seconds != null && seconds > 0) {
        content = Stack(
          clipBehavior: Clip.none,
          children: [
            content,
            Positioned(
              top: -2,
              right: -2,
              child: _CountdownBadge(seconds: seconds),
            ),
          ],
        );
      }
    } else if (isSelected && !isReservePending) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -3,
            right: -3,
            child: Icon(
              Icons.check_circle_rounded,
              size: 11,
              color: AppBranding.goldAccent,
            ),
          ),
        ],
      );
    }

    return content;
  }

  String _primaryLabel() {
    if (selectModeEnabled && isSelected) {
      return '$number';
    }
    if (isSelected) {
      return '$number';
    }
    return '$number';
  }
}

class _NumberLabel extends StatelessWidget {
  const _NumberLabel({
    required this.label,
    required this.color,
    required this.large,
    this.dimmed = false,
  });

  final String label;
  final Color color;
  final bool large;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    final child = dimmed ? Opacity(opacity: 0.42, child: text) : text;

    if (!large) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: AppBranding.goldAccent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${seconds}s',
        style: const TextStyle(
          color: AppBranding.brandPurple,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          height: 1,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
