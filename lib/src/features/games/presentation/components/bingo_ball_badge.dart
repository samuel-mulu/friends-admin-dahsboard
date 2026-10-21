import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

class BingoBallBadge extends StatelessWidget {
  const BingoBallBadge({
    super.key,
    this.number,
    this.letter,
    this.size = 44.0,
    this.isLatest = false,
    this.animated = true,
  });

  final int? number;
  final String? letter;
  final double size;
  final bool isLatest;
  final bool animated;

  static String getLetter(int number) {
    if (number <= 15) return 'B';
    if (number <= 30) return 'I';
    if (number <= 45) return 'N';
    if (number <= 60) return 'G';
    return 'O';
  }

  static Color getColor(int number) {
    if (number <= 15) return const Color(0xFFE53935); // B - Red
    if (number <= 30) return const Color(0xFFFB8C00); // I - Orange
    if (number <= 45) return const Color(0xFF1E88E5); // N - Blue
    if (number <= 60) return const Color(0xFF43A047); // G - Green
    return const Color(0xFF8E24AA);                   // O - Purple
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmpty = number == null;

    if (isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            radius: 1.05,
            colors: [
              isDark ? const Color(0xFF3A3A3A) : AppBranding.lightSurface,
              isDark ? const Color(0xFF2A2A2A) : AppBranding.lightSurfaceMuted,
              isDark ? const Color(0xFF1F1F1F) : AppBranding.lightOutline,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            '--',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final effectiveNumber = number!;
    final effectiveLetter = letter ?? getLetter(effectiveNumber);
    final baseColor = isLatest
        ? (isDark ? AppBranding.gold : AppBranding.goldDark)
        : getColor(effectiveNumber);

    final highlight = Color.lerp(baseColor, Colors.white, 0.42)!;
    final shadowTone = Color.lerp(baseColor, Colors.black, 0.28)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 1.05,
          colors: [highlight, baseColor, shadowTone],
          stops: const [0.0, 0.58, 1.0],
        ),
        boxShadow: [
          if (isLatest)
            BoxShadow(
              color: baseColor.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            )
          else ...[
            BoxShadow(
              color: baseColor.withValues(alpha: 0.38),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isLatest ? 0.85 : 0.28),
          width: isLatest ? 1.5 : 1.2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              effectiveLetter,
              style: TextStyle(
                color: isLatest
                    ? AppBranding.casinoPurpleDeep
                    : Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.bold,
                fontSize: size * 0.24,
                height: 1.0,
              ),
            ),
            Text(
              effectiveNumber.toString(),
              style: TextStyle(
                color: isLatest ? AppBranding.casinoPurpleDeep : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.36,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
